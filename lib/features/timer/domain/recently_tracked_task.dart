class RecentlyTrackedTask {
  const RecentlyTrackedTask({
    required this.taskId,
    required this.taskName,
    required this.category,
    required this.lastTrackedAt,
    required this.totalDurationSeconds,
    required this.sessionCount,
  });

  final int taskId;
  final String taskName;
  final String category;
  final DateTime lastTrackedAt;
  final int totalDurationSeconds;
  final int sessionCount;
}
