class HistoryEntry {
  const HistoryEntry({
    required this.taskId,
    required this.taskName,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
  });

  final int taskId;
  final String taskName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
}
