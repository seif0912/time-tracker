class TimeSummary {
  const TimeSummary({required this.totalSeconds, required this.sessionCount});

  final int totalSeconds;
  final int sessionCount;

  Duration get totalDuration => Duration(seconds: totalSeconds);
}
