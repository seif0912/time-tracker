enum TimerStatus { idle, running, paused }

class TimerSessionState {
  final TimerStatus status;
  final int accumulatedSeconds;
  final int currentElapsedSeconds;
  final DateTime startedAt;
  final DateTime? currentSegmentStartedAt;
  final int taskId;

  const TimerSessionState({
    required this.status,
    required this.startedAt,
    required this.taskId,
    this.accumulatedSeconds = 0,
    this.currentElapsedSeconds = 0,
    this.currentSegmentStartedAt,
  });

  int get totalElapsedSeconds => accumulatedSeconds + currentElapsedSeconds;

  TimerSessionState copyWith({
    TimerStatus? status,
    int? accumulatedSeconds,
    int? currentElapsedSeconds,
    DateTime? startedAt,
    Object? currentSegmentStartedAt = _notProvided,
    int? taskId,
  }) {
    return TimerSessionState(
      status: status ?? this.status,
      accumulatedSeconds: accumulatedSeconds ?? this.accumulatedSeconds,
      currentElapsedSeconds:
          currentElapsedSeconds ?? this.currentElapsedSeconds,
      startedAt: startedAt ?? this.startedAt,
      currentSegmentStartedAt: currentSegmentStartedAt == _notProvided
          ? this.currentSegmentStartedAt
          : currentSegmentStartedAt as DateTime?,
      taskId: taskId ?? this.taskId,
    );
  }

  static const _notProvided = Object();
}

class TimerState {
  final Map<int, TimerSessionState> sessions;

  const TimerState({this.sessions = const {}});

  TimerSessionState? sessionForTask(int taskId) {
    return sessions[taskId];
  }

  TimerSessionState? get runningSession {
    for (final session in sessions.values) {
      if (session.status == TimerStatus.running) {
        return session;
      }
    }

    return null;
  }

  bool get hasRunningSession => runningSession != null;

  TimerState copyWith({Map<int, TimerSessionState>? sessions}) {
    return TimerState(sessions: sessions ?? this.sessions);
  }
}
