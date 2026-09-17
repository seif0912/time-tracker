import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_controller.dart';
import '../../../core/sync/sync_providers.dart';
import '../data/active_timer_providers.dart';
import '../data/time_entry_providers.dart';
import '../domain/timer_state.dart';
import '../../authentication/data/current_user_provider.dart';

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
    final user = ref.read(currentUserProvider);

    if (user == null) {
      return;
    }

    final repository = ref.read(activeTimerRepositoryProvider);

    final activeTimers = await repository.getForUser(user.uid);

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
    final user = ref.read(currentUserProvider);

    if (user == null) {
      return;
    }

    await ref
        .read(activeTimerRepositoryProvider)
        .save(userId: user.uid, session: session);
  }

  Future<void> _deletePersistedSession(int taskId) async {
    final user = ref.read(currentUserProvider);

    if (user == null) {
      return;
    }

    await ref
        .read(activeTimerRepositoryProvider)
        .deleteForTask(userId: user.uid, taskId: taskId);
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

    if (segmentStart == null) {
      return;
    }

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

    if (session == null) {
      return;
    }

    var totalSeconds = session.accumulatedSeconds;

    if (session.status == TimerStatus.running &&
        session.currentSegmentStartedAt != null) {
      totalSeconds += DateTime.now()
          .difference(session.currentSegmentStartedAt!)
          .inSeconds;
    }

    _ticker?.cancel();

    final user = ref.read(currentUserProvider);

    if (totalSeconds <= 0) {
      _removeSession(taskId);

      if (user != null) {
        await _deletePersistedSession(taskId);
      }

      return;
    }

    if (user == null) {
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
