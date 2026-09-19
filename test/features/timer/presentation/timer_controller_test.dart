import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:time_tracker/features/authentication/data/current_user_id_provider.dart';
import 'package:time_tracker/features/timer/domain/timer_state.dart';
import 'package:time_tracker/features/timer/presentation/timer_controller.dart';

import 'package:drift/native.dart';

import 'package:time_tracker/core/services/database/app_database.dart';
import 'package:time_tracker/features/timer/data/active_timer_providers.dart';
import 'package:time_tracker/features/timer/data/active_timer_repository.dart';

import 'package:time_tracker/features/timer/data/time_entry_providers.dart';
import 'package:time_tracker/features/timer/data/time_entry_repository.dart';

void main() {
  group('TimerController', () {
    test('starts with an empty state', () {
      final container = ProviderContainer(
        overrides: [currentUserIdProvider.overrideWithValue(null)],
      );

      addTearDown(container.dispose);

      final state = container.read(timerControllerProvider);

      expect(state.sessions, isEmpty);
      expect(state.runningSession, isNull);
    });

    test('start creates a running session', () {
      final container = ProviderContainer(
        overrides: [currentUserIdProvider.overrideWithValue(null)],
      );

      addTearDown(container.dispose);

      final controller = container.read(timerControllerProvider.notifier);

      controller.start(taskId: 1);

      final state = container.read(timerControllerProvider);
      final session = state.sessionForTask(1);

      expect(session, isNotNull);
      expect(session!.status, TimerStatus.running);
      expect(session.taskId, 1);
      expect(session.startedAt, isNotNull);
      expect(session.currentSegmentStartedAt, isNotNull);
      expect(state.hasRunningSession, isTrue);
    });

    test('cannot start another task while a timer is running', () {
      final container = ProviderContainer(
        overrides: [currentUserIdProvider.overrideWithValue(null)],
      );

      addTearDown(container.dispose);

      final controller = container.read(timerControllerProvider.notifier);

      controller.start(taskId: 1);
      controller.start(taskId: 2);

      final state = container.read(timerControllerProvider);

      expect(state.sessions, hasLength(1));
      expect(state.sessionForTask(1), isNotNull);
      expect(state.sessionForTask(2), isNull);
    });

    test('pause changes a running session to paused', () {
      final container = ProviderContainer(
        overrides: [currentUserIdProvider.overrideWithValue(null)],
      );

      addTearDown(container.dispose);

      final controller = container.read(timerControllerProvider.notifier);

      controller.start(taskId: 1);
      controller.pause(1);

      final session = container.read(timerControllerProvider).sessionForTask(1);

      expect(session, isNotNull);
      expect(session!.status, TimerStatus.paused);
      expect(session.currentSegmentStartedAt, isNull);
      expect(session.currentElapsedSeconds, 0);
    });

    test('resume changes a paused session back to running', () {
      final container = ProviderContainer(
        overrides: [currentUserIdProvider.overrideWithValue(null)],
      );

      addTearDown(container.dispose);

      final controller = container.read(timerControllerProvider.notifier);

      controller.start(taskId: 1);
      controller.pause(1);
      controller.resume(1);

      final session = container.read(timerControllerProvider).sessionForTask(1);

      expect(session, isNotNull);
      expect(session!.status, TimerStatus.running);
      expect(session.currentSegmentStartedAt, isNotNull);
    });

    test('reset removes the session', () {
      final container = ProviderContainer(
        overrides: [currentUserIdProvider.overrideWithValue(null)],
      );

      addTearDown(container.dispose);

      final controller = container.read(timerControllerProvider.notifier);

      controller.start(taskId: 1);
      controller.reset(1);

      final state = container.read(timerControllerProvider);

      expect(state.sessionForTask(1), isNull);
      expect(state.hasRunningSession, isFalse);
    });
    test('start persists the active timer', () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());

      final repository = ActiveTimerRepository(database);

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('test-user'),
          activeTimerRepositoryProvider.overrideWithValue(repository),
        ],
      );

      addTearDown(() async {
        container.dispose();
        await database.close();
      });

      final controller = container.read(timerControllerProvider.notifier);

      controller.start(taskId: 1);

      await Future<void>.delayed(Duration.zero);

      final timers = await repository.getForUser('test-user');

      expect(timers, hasLength(1));
      expect(timers.first.taskId, 1);
      expect(timers.first.userId, 'test-user');
      expect(timers.first.status, TimerStatus.running.name);
    });
    test('restores persisted active timers when created', () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());

      final repository = ActiveTimerRepository(database);

      final persistedSession = TimerSessionState(
        status: TimerStatus.paused,
        startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        taskId: 1,
        accumulatedSeconds: 120,
      );

      await repository.save(userId: 'test-user', session: persistedSession);

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('test-user'),
          activeTimerRepositoryProvider.overrideWithValue(repository),
        ],
      );

      addTearDown(() async {
        container.dispose();
        await database.close();
      });

      // Creating/reading the controller triggers build().
      container.read(timerControllerProvider);

      // _restoreActiveTimers() runs asynchronously.
      await Future<void>.delayed(Duration.zero);

      final state = container.read(timerControllerProvider);
      final session = state.sessionForTask(1);

      expect(session, isNotNull);
      expect(session!.status, TimerStatus.paused);
      expect(session.taskId, 1);
      expect(session.accumulatedSeconds, 120);
      expect(session.currentElapsedSeconds, 0);
    });
    test('restores a running timer with derived elapsed time', () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());

      final repository = ActiveTimerRepository(database);

      final startedAt = DateTime.now().subtract(const Duration(seconds: 5));

      await repository.save(
        userId: 'test-user',
        session: TimerSessionState(
          status: TimerStatus.running,
          startedAt: startedAt,
          currentSegmentStartedAt: startedAt,
          taskId: 1,
          accumulatedSeconds: 30,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('test-user'),
          activeTimerRepositoryProvider.overrideWithValue(repository),
        ],
      );

      addTearDown(() async {
        container.dispose();
        await database.close();
      });

      container.read(timerControllerProvider);

      await Future<void>.delayed(Duration.zero);

      final state = container.read(timerControllerProvider);
      final session = state.sessionForTask(1);

      expect(session, isNotNull);
      expect(session!.status, TimerStatus.running);
      expect(session.taskId, 1);
      expect(session.accumulatedSeconds, 30);
      expect(session.currentElapsedSeconds, greaterThanOrEqualTo(5));
      expect(session.totalElapsedSeconds, greaterThanOrEqualTo(35));
    });
    test('stop creates a time entry and removes the active timer', () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());

      final activeTimerRepository = ActiveTimerRepository(database);
      final timeEntryRepository = TimeEntryRepository(database);

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('test-user'),
          activeTimerRepositoryProvider.overrideWithValue(
            activeTimerRepository,
          ),
          timeEntryRepositoryProvider.overrideWithValue(timeEntryRepository),
        ],
      );

      addTearDown(() async {
        container.dispose();
        await database.close();
      });

      final controller = container.read(timerControllerProvider.notifier);

      controller.start(taskId: 1);

      // Give the asynchronous persistence operation time to complete.
      await Future<void>.delayed(Duration.zero);

      await Future<void>.delayed(const Duration(seconds: 1));

      await controller.stop(1);

      final state = container.read(timerControllerProvider);

      expect(state.sessionForTask(1), isNull);

      final activeTimers = await activeTimerRepository.getForUser('test-user');

      expect(activeTimers, isEmpty);

      final entries = await timeEntryRepository.getEntriesForUser('test-user');

      expect(entries, hasLength(1));
      expect(entries.first.taskId, 1);
      expect(entries.first.durationSeconds, greaterThanOrEqualTo(1));
      expect(entries.first.endedAt, isNotNull);
    });
    test('pause and resume preserve accumulated time when stopped', () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());

      final activeTimerRepository = ActiveTimerRepository(database);
      final timeEntryRepository = TimeEntryRepository(database);

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('test-user'),
          activeTimerRepositoryProvider.overrideWithValue(
            activeTimerRepository,
          ),
          timeEntryRepositoryProvider.overrideWithValue(timeEntryRepository),
        ],
      );

      addTearDown(() async {
        container.dispose();
        await database.close();
      });

      final controller = container.read(timerControllerProvider.notifier);

      // First segment.
      controller.start(taskId: 1);

      await Future<void>.delayed(const Duration(seconds: 1));

      controller.pause(1);

      final pausedSession = container
          .read(timerControllerProvider)
          .sessionForTask(1);

      expect(pausedSession, isNotNull);
      expect(pausedSession!.status, TimerStatus.paused);
      expect(pausedSession.accumulatedSeconds, greaterThanOrEqualTo(1));
      expect(pausedSession.currentElapsedSeconds, 0);

      final accumulatedAfterPause = pausedSession.accumulatedSeconds;

      // Second segment.
      controller.resume(1);

      await Future<void>.delayed(const Duration(seconds: 1));

      await controller.stop(1);

      final entries = await timeEntryRepository.getEntriesForUser('test-user');

      expect(entries, hasLength(1));

      final duration = entries.first.durationSeconds!;

      expect(duration, greaterThanOrEqualTo(accumulatedAfterPause + 1));
    });
    test('stop paused timer creates entry using accumulated time', () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());

      final activeTimerRepository = ActiveTimerRepository(database);
      final timeEntryRepository = TimeEntryRepository(database);

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('test-user'),
          activeTimerRepositoryProvider.overrideWithValue(
            activeTimerRepository,
          ),
          timeEntryRepositoryProvider.overrideWithValue(timeEntryRepository),
        ],
      );

      addTearDown(() async {
        container.dispose();
        await database.close();
      });

      final controller = container.read(timerControllerProvider.notifier);

      controller.start(taskId: 1);

      await Future<void>.delayed(const Duration(seconds: 1));

      controller.pause(1);

      final pausedSession = container
          .read(timerControllerProvider)
          .sessionForTask(1);

      expect(pausedSession, isNotNull);
      expect(pausedSession!.status, TimerStatus.paused);
      expect(pausedSession.accumulatedSeconds, greaterThanOrEqualTo(1));

      final accumulatedSeconds = pausedSession.accumulatedSeconds;

      await controller.stop(1);

      final entries = await timeEntryRepository.getEntriesForUser('test-user');

      expect(entries, hasLength(1));
      expect(entries.first.taskId, 1);
      expect(entries.first.durationSeconds, accumulatedSeconds);

      final activeTimers = await activeTimerRepository.getForUser('test-user');

      expect(activeTimers, isEmpty);

      expect(container.read(timerControllerProvider).sessionForTask(1), isNull);
    });
    test(
      'reset paused timer removes persisted timer without creating entry',
      () async {
        final database = AppDatabase.forTesting(NativeDatabase.memory());

        final activeTimerRepository = ActiveTimerRepository(database);
        final timeEntryRepository = TimeEntryRepository(database);

        final container = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue('test-user'),
            activeTimerRepositoryProvider.overrideWithValue(
              activeTimerRepository,
            ),
            timeEntryRepositoryProvider.overrideWithValue(timeEntryRepository),
          ],
        );

        addTearDown(() async {
          container.dispose();
          await database.close();
        });

        final controller = container.read(timerControllerProvider.notifier);

        controller.start(taskId: 1);

        await Future<void>.delayed(const Duration(seconds: 1));

        controller.pause(1);

        final pausedSession = container
            .read(timerControllerProvider)
            .sessionForTask(1);

        expect(pausedSession, isNotNull);
        expect(pausedSession!.status, TimerStatus.paused);

        // Give the persistence operation time to complete.
        await Future<void>.delayed(Duration.zero);

        final persistedBeforeReset = await activeTimerRepository.getForTask(
          userId: 'test-user',
          taskId: 1,
        );

        expect(persistedBeforeReset, isNotNull);

        controller.reset(1);

        // Give the asynchronous deletion operation time to complete.
        await Future<void>.delayed(Duration.zero);

        final state = container.read(timerControllerProvider);

        expect(state.sessionForTask(1), isNull);

        final persistedAfterReset = await activeTimerRepository.getForTask(
          userId: 'test-user',
          taskId: 1,
        );

        expect(persistedAfterReset, isNull);

        final entries = await timeEntryRepository.getEntriesForUser(
          'test-user',
        );

        expect(entries, isEmpty);
      },
    );
  });
}
