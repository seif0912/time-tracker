import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_controller.dart';
import '../../../core/sync/sync_providers.dart';
import '../data/active_timer_providers.dart';
import '../data/time_entry_providers.dart';
import '../domain/timer_state.dart';
import '../../authentication/data/current_user_id_provider.dart';

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

    unawaited(_restoreActiveTimers());

    return const TimerState();
  }

  Future<void> _restoreActiveTimers() async {
    final userId = ref.read(currentUserIdProvider);

    if (userId == null) {
      return;
    }

    final repository = ref.read(activeTimerRepositoryProvider);

    final activeTimers = await repository.getForUser(userId);

    if (activeTimers.isEmpty) {
      return;
    }

    final sessions = <int, TimerSessionState>{
      for (final timer in activeTimers)
        timer.taskId: repository.toSession(timer),
    };

    state = state.copyWith(sessions: sessions);

    if (state.hasRunningSession) {
      _startTicker();
    }
  }

  Future<void> _persistSession(TimerSessionState session) async {
    final userId = ref.read(currentUserIdProvider);

    if (userId == null) {
      return;
    }

    await ref
        .read(activeTimerRepositoryProvider)
        .save(userId: userId, session: session);
  }

  Future<void> _saveSegment({
    required int taskId,
    required DateTime startedAt,
    required DateTime endedAt,
    required int durationSeconds,
  }) async {
    final userId = ref.read(currentUserIdProvider);

    if (userId == null || durationSeconds <= 0) return;

    await ref
        .read(timeEntryRepositoryProvider)
        .createTimeEntrySegment(
          userId: userId,
          taskId: taskId,
          startedAt: startedAt,
          endedAt: endedAt,
          durationSeconds: durationSeconds,
        );
  }

  Future<void> _deletePersistedSession(int taskId) async {
    final userId = ref.read(currentUserIdProvider);

    if (userId == null) {
      return;
    }

    await ref
        .read(activeTimerRepositoryProvider)
        .deleteForTask(userId: userId, taskId: taskId);
  }

  void start({required int taskId}) {
    final existingSession = state.sessionForTask(taskId);

    if (existingSession != null &&
        existingSession.status == TimerStatus.running) {
      return;
    }

    // A task must be stopped before another task can be started.
    // Allow starting only when there are no sessions, or when this
    // task already owns the existing session.
    if (state.sessions.isNotEmpty && !state.sessions.containsKey(taskId)) {
      return;
    }

    if (state.hasRunningSession) {
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

    unawaited(_persistSession(updatedSession));

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

      if (segmentStart == null) {
        return;
      }

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

    final now = DateTime.now();
    final segmentDuration = now.difference(segmentStart).inSeconds;

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

    // Save the segment independently when the timer is paused.
    unawaited(
      _saveSegment(
        taskId: taskId,
        startedAt: segmentStart,
        endedAt: now,
        durationSeconds: segmentDuration,
      ),
    );

    unawaited(_persistSession(updatedSession));
  }

  void resume(int taskId) {
    final session = state.sessionForTask(taskId);

    if (session == null || session.status != TimerStatus.paused) {
      return;
    }

    if (state.hasRunningSession) {
      return;
    }

    // Do not resume a task if another task still has an active session.
    if (state.sessions.keys.any((id) => id != taskId)) {
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

    unawaited(_persistSession(updatedSession));

    _startTicker();
  }

  Future<void> stop(int taskId) async {
    final session = state.sessionForTask(taskId);

    if (session == null) return;

    final now = DateTime.now();

    DateTime? finalSegmentStartedAt;
    var finalSegmentDuration = 0;

    if (session.status == TimerStatus.running &&
        session.currentSegmentStartedAt != null) {
      finalSegmentStartedAt = session.currentSegmentStartedAt;
      finalSegmentDuration = now
          .difference(session.currentSegmentStartedAt!)
          .inSeconds;
    }

    final totalSeconds = session.accumulatedSeconds + finalSegmentDuration;

    _ticker?.cancel();

    final userId = ref.read(currentUserIdProvider);

    if (totalSeconds <= 0) {
      _removeSession(taskId);

      if (userId != null) {
        await _deletePersistedSession(taskId);
      }

      return;
    }

    if (userId == null) return;

    final syncId = ref.read(syncIdGeneratorProvider).generate();

    final repository = ref.read(timeEntryRepositoryProvider);

    await repository.completeTimeEntry(
      taskId: taskId,
      syncId: syncId,
      userId: userId,
      startedAt: session.startedAt,
      endedAt: now,
      durationSeconds: totalSeconds,
      segmentStartedAt: finalSegmentStartedAt,
      segmentDurationSeconds: finalSegmentDuration,
    );

    await _deletePersistedSession(taskId);

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

    unawaited(_deletePersistedSession(taskId));

    final runningSession = state.runningSession;

    if (runningSession != null) {
      _startTicker();
    }
  }
}
