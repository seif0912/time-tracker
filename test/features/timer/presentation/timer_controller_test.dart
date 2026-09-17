import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:time_tracker/features/authentication/data/current_user_provider.dart';
import 'package:time_tracker/features/timer/domain/timer_state.dart';
import 'package:time_tracker/features/timer/presentation/timer_controller.dart';

void main() {
  group('TimerController', () {
    test('starts with an empty state', () {
      final container = ProviderContainer(
        overrides: [currentUserProvider.overrideWithValue(null)],
      );

      addTearDown(container.dispose);

      final state = container.read(timerControllerProvider);

      expect(state.sessions, isEmpty);
      expect(state.runningSession, isNull);
    });

    test('start creates a running session', () {
      final container = ProviderContainer(
        overrides: [currentUserProvider.overrideWithValue(null)],
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
        overrides: [currentUserProvider.overrideWithValue(null)],
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
        overrides: [currentUserProvider.overrideWithValue(null)],
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
        overrides: [currentUserProvider.overrideWithValue(null)],
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
        overrides: [currentUserProvider.overrideWithValue(null)],
      );

      addTearDown(container.dispose);

      final controller = container.read(timerControllerProvider.notifier);

      controller.start(taskId: 1);
      controller.reset(1);

      final state = container.read(timerControllerProvider);

      expect(state.sessionForTask(1), isNull);
      expect(state.hasRunningSession, isFalse);
    });
  });
}
