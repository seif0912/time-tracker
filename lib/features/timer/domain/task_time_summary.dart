class TaskTimeSummary {
  const TaskTimeSummary({
    required this.taskId,
    required this.totalSeconds,
    required this.sessionCount,
  });

  final int taskId;
  final int totalSeconds;
  final int sessionCount;
}
