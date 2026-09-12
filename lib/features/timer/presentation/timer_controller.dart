import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_controller.dart';
import '../../../core/sync/sync_providers.dart';
import '../../authentication/data/auth_providers.dart';
import '../data/time_entry_providers.dart';
import '../domain/timer_state.dart';

final timerControllerProvider = NotifierProvider<TimerController, TimerState>(
  TimerController.new,
);

class TimerController extends Notifier<TimerState> {
  Timer? _ticker;

  @override
  TimerState build() {
    ref.onDispose(() {
      _ticker?.cancel();
    });

    return const TimerState();
  }

  void start({required int taskId}) {
    final existingSession = state.sessionForTask(taskId);

    if (existingSession != null &&
        existingSession.status == TimerStatus.running) {
      return;
    }

    final runningSession = state.runningSession;

    if (runningSession != null) {
      return;
    }

    final now = DateTime.now();

    final session =
        existingSession ??
        TimerSessionState(
          status: TimerStatus.running,
          startedAt: now,
          currentSegmentStartedAt: now,
          taskId: taskId,
        );

    final updatedSession = session.copyWith(
      status: TimerStatus.running,
      currentSegmentStartedAt: now,
      currentElapsedSeconds: 0,
    );

    final sessions = Map<int, TimerSessionState>.from(state.sessions);

    sessions[taskId] = updatedSession;

    state = state.copyWith(sessions: sessions);

    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final runningSession = state.runningSession;

      if (runningSession == null) {
        _ticker?.cancel();
        return;
      }

      final segmentStart = runningSession.currentSegmentStartedAt;

      if (segmentStart == null) return;

      final elapsed = DateTime.now().difference(segmentStart).inSeconds;

      final updatedSession = runningSession.copyWith(
        currentElapsedSeconds: elapsed,
      );

      final sessions = Map<int, TimerSessionState>.from(state.sessions);

      sessions[runningSession.taskId] = updatedSession;

      state = state.copyWith(sessions: sessions);
    });
  }

  void pause(int taskId) {
    final session = state.sessionForTask(taskId);

    if (session == null || session.status != TimerStatus.running) {
      return;
    }

    final segmentStart = session.currentSegmentStartedAt;

    if (segmentStart == null) return;

    final segmentDuration = DateTime.now().difference(segmentStart).inSeconds;

    _ticker?.cancel();

    final updatedSession = session.copyWith(
      status: TimerStatus.paused,
      accumulatedSeconds: session.accumulatedSeconds + segmentDuration,
      currentElapsedSeconds: 0,
      currentSegmentStartedAt: null,
    );

    final sessions = Map<int, TimerSessionState>.from(state.sessions);

    sessions[taskId] = updatedSession;

    state = state.copyWith(sessions: sessions);
  }

  void resume(int taskId) {
    final session = state.sessionForTask(taskId);

    if (session == null || session.status != TimerStatus.paused) {
      return;
    }

    if (state.hasRunningSession) {
      return;
    }

    final now = DateTime.now();

    final updatedSession = session.copyWith(
      status: TimerStatus.running,
      currentSegmentStartedAt: now,
      currentElapsedSeconds: 0,
    );

    final sessions = Map<int, TimerSessionState>.from(state.sessions);

    sessions[taskId] = updatedSession;

    state = state.copyWith(sessions: sessions);

    _startTicker();
  }

  Future<void> stop(int taskId) async {
    final session = state.sessionForTask(taskId);

    if (session == null) return;

    var totalSeconds = session.accumulatedSeconds;

    if (session.status == TimerStatus.running &&
        session.currentSegmentStartedAt != null) {
      totalSeconds += DateTime.now()
          .difference(session.currentSegmentStartedAt!)
          .inSeconds;
    }

    _ticker?.cancel();

    if (totalSeconds <= 0) {
      _removeSession(taskId);
      return;
    }

    final authRepository = ref.read(authRepositoryProvider);
    final user = authRepository.currentUser;

    if (user == null) {
      _removeSession(taskId);
      return;
    }

    final syncId = ref.read(syncIdGeneratorProvider).generate();

    final repository = ref.read(timeEntryRepositoryProvider);

    await repository.createTimeEntry(
      taskId: taskId,
      syncId: syncId,
      userId: user.uid,
      startedAt: session.startedAt,
      endedAt: DateTime.now(),
      durationSeconds: totalSeconds,
    );

    _removeSession(taskId);

    try {
      await ref.read(syncControllerProvider.notifier).sync();
    } catch (_) {
      // The entry remains pending locally and will sync
      // when connectivity returns.
    }

    final remainingRunningSession = state.runningSession;

    if (remainingRunningSession != null) {
      _startTicker();
    }
  }

  void _removeSession(int taskId) {
    final sessions = Map<int, TimerSessionState>.from(state.sessions);

    sessions.remove(taskId);

    state = state.copyWith(sessions: sessions);
  }

  void reset(int taskId) {
    final session = state.sessionForTask(taskId);

    if (session?.status == TimerStatus.running) {
      _ticker?.cancel();
    }

    _removeSession(taskId);

    final runningSession = state.runningSession;

    if (runningSession != null) {
      _startTicker();
    }
  }
}
