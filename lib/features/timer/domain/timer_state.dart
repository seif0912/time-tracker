enum TimerStatus { idle, running, paused }

class TimerState {
  final TimerStatus status;
  final int accumulatedSeconds;
  final int currentElapsedSeconds;
  final DateTime? startedAt;
  final DateTime? currentSegmentStartedAt;
  final int? taskId;

  const TimerState({
    this.status = TimerStatus.idle,
    this.accumulatedSeconds = 0,
    this.currentElapsedSeconds = 0,
    this.startedAt,
    this.currentSegmentStartedAt,
    this.taskId,
  });

  int get totalElapsedSeconds => accumulatedSeconds + currentElapsedSeconds;

  TimerState copyWith({
    TimerStatus? status,
    int? accumulatedSeconds,
    int? currentElapsedSeconds,
    DateTime? startedAt,
    DateTime? currentSegmentStartedAt,
    int? taskId,
  }) {
    return TimerState(
      status: status ?? this.status,
      accumulatedSeconds: accumulatedSeconds ?? this.accumulatedSeconds,
      currentElapsedSeconds:
          currentElapsedSeconds ?? this.currentElapsedSeconds,
      startedAt: startedAt ?? this.startedAt,
      currentSegmentStartedAt:
          currentSegmentStartedAt ?? this.currentSegmentStartedAt,
      taskId: taskId ?? this.taskId,
    );
  }
}
