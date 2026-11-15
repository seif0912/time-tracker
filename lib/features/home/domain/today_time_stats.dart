class TodayTimeStats {
  const TodayTimeStats({
    required this.totalSeconds,
    required this.hourlySeconds,
  });

  final int totalSeconds;

  /// Exactly 24 values, one for each hour of the local calendar day.
  final List<int> hourlySeconds;

  double progressForGoal(int goalSeconds) {
    if (goalSeconds <= 0) return 0;
    return totalSeconds / goalSeconds;
  }
}
