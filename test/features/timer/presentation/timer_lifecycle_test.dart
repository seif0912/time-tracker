// import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:time_tracker/core/services/database/app_database.dart';
import 'package:time_tracker/features/authentication/data/current_user_id_provider.dart';
import 'package:time_tracker/features/timer/data/active_timer_providers.dart';
import 'package:time_tracker/features/timer/data/active_timer_repository.dart';
import 'package:time_tracker/features/timer/domain/timer_state.dart';
import 'package:time_tracker/features/timer/presentation/timer_controller.dart';

void main() {
  late AppDatabase database;
  late ActiveTimerRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ActiveTimerRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue('user-1'),
        activeTimerRepositoryProvider.overrideWithValue(repository),
      ],
    );
  }

  group('Timer lifecycle recovery', () {
    test('restores a paused timer after controller recreation', () async {
      final startedAt = DateTime(2026, 1, 1, 10);
      final session = TimerSessionState(
        status: TimerStatus.paused,
        startedAt: startedAt,
        taskId: 1,
        accumulatedSeconds: 120,
        currentElapsedSeconds: 0,
        currentSegmentStartedAt: null,
      );

      await repository.save(userId: 'user-1', session: session);

      final container = createContainer();
      addTearDown(container.dispose);

      final restored = container.read(timerControllerProvider);

      // Allow the asynchronous restoration to complete.
      await Future<void>.delayed(Duration.zero);

      final restoredSession = container
          .read(timerControllerProvider)
          .sessionForTask(1);

      expect(restored, isNotNull);
      expect(restoredSession, isNotNull);
      expect(restoredSession!.status, TimerStatus.paused);
      expect(restoredSession.accumulatedSeconds, 120);
      expect(restoredSession.currentElapsedSeconds, 0);
      expect(restoredSession.startedAt, startedAt);
      expect(restoredSession.currentSegmentStartedAt, isNull);
    });

    test('restores a running timer after controller recreation', () async {
      final startedAt = DateTime(2026, 1, 1, 10, 0, 0);

      final session = TimerSessionState(
        status: TimerStatus.running,
        startedAt: startedAt,
        taskId: 1,
        accumulatedSeconds: 60,
        currentElapsedSeconds: 0,
        currentSegmentStartedAt: startedAt,
      );

      await repository.save(userId: 'user-1', session: session);

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(timerControllerProvider);

      // Allow asynchronous restoration to complete.
      await Future<void>.delayed(Duration.zero);

      final restored = container
          .read(timerControllerProvider)
          .sessionForTask(1);

      expect(restored, isNotNull);
      expect(restored!.status, TimerStatus.running);
      expect(restored.accumulatedSeconds, 60);
      expect(restored.currentSegmentStartedAt, isNotNull);

      // SQLite stores the timestamp at millisecond precision.
      expect(
        restored.currentSegmentStartedAt!.millisecondsSinceEpoch,
        startedAt.millisecondsSinceEpoch,
      );

      // The persisted start time is far enough in the past that
      // elapsed time must be derived from it.
      expect(restored.currentElapsedSeconds, greaterThanOrEqualTo(1));

      // Confirm the restored timer continues ticking.
      final elapsedBefore = restored.currentElapsedSeconds;

      await Future<void>.delayed(const Duration(seconds: 1));

      final elapsedAfter = container
          .read(timerControllerProvider)
          .sessionForTask(1)!
          .currentElapsedSeconds;

      expect(elapsedAfter, greaterThanOrEqualTo(elapsedBefore));
    });
    test('restores multiple paused timers', () async {
      final sessionOne = TimerSessionState(
        status: TimerStatus.paused,
        startedAt: DateTime(2026, 1, 1, 10),
        taskId: 1,
        accumulatedSeconds: 120,
      );

      final sessionTwo = TimerSessionState(
        status: TimerStatus.paused,
        startedAt: DateTime(2026, 1, 1, 11),
        taskId: 2,
        accumulatedSeconds: 300,
      );

      await repository.save(userId: 'user-1', session: sessionOne);

      await repository.save(userId: 'user-1', session: sessionTwo);

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(timerControllerProvider);

      await Future<void>.delayed(Duration.zero);

      final state = container.read(timerControllerProvider);

      expect(state.sessions, hasLength(2));
      expect(state.sessionForTask(1)!.accumulatedSeconds, 120);
      expect(state.sessionForTask(2)!.accumulatedSeconds, 300);
      expect(state.hasRunningSession, false);
    });

    test('restores only timers belonging to the current user', () async {
      final userOneSession = TimerSessionState(
        status: TimerStatus.paused,
        startedAt: DateTime(2026, 1, 1),
        taskId: 1,
        accumulatedSeconds: 100,
      );

      final userTwoSession = TimerSessionState(
        status: TimerStatus.paused,
        startedAt: DateTime(2026, 1, 1),
        taskId: 2,
        accumulatedSeconds: 200,
      );

      await repository.save(userId: 'user-1', session: userOneSession);

      await repository.save(userId: 'user-2', session: userTwoSession);

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(timerControllerProvider);

      await Future<void>.delayed(Duration.zero);

      final state = container.read(timerControllerProvider);

      expect(state.sessions, hasLength(1));
      expect(state.sessionForTask(1), isNotNull);
      expect(state.sessionForTask(2), isNull);
    });

    test(
      'does not restore timers when there is no authenticated user',
      () async {
        final session = TimerSessionState(
          status: TimerStatus.paused,
          startedAt: DateTime(2026, 1, 1),
          taskId: 1,
          accumulatedSeconds: 100,
        );

        await repository.save(userId: 'user-1', session: session);

        final container = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue(null),
            activeTimerRepositoryProvider.overrideWithValue(repository),
          ],
        );

        addTearDown(container.dispose);

        final state = container.read(timerControllerProvider);

        await Future<void>.delayed(Duration.zero);

        expect(state.sessions, isEmpty);
        expect(container.read(timerControllerProvider).sessions, isEmpty);
      },
    );

    test('persisted running timer survives controller disposal', () async {
      final firstContainer = createContainer();

      final controller = firstContainer.read(timerControllerProvider.notifier);

      controller.start(taskId: 1);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final persistedBeforeDispose = await repository.getForTask(
        userId: 'user-1',
        taskId: 1,
      );

      expect(persistedBeforeDispose, isNotNull);
      expect(persistedBeforeDispose!.status, TimerStatus.running.name);

      firstContainer.dispose();

      // Simulate a new controller after the old one has been destroyed.
      final secondContainer = createContainer();
      addTearDown(secondContainer.dispose);

      secondContainer.read(timerControllerProvider);

      await Future<void>.delayed(Duration.zero);

      final restored = secondContainer
          .read(timerControllerProvider)
          .sessionForTask(1);

      expect(restored, isNotNull);
      expect(restored!.status, TimerStatus.running);
      expect(restored.currentElapsedSeconds, greaterThanOrEqualTo(0));
    });
  });
}
