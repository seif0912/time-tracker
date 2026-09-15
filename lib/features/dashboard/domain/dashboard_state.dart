import '../../timer/domain/task_time_summary.dart';
import '../../timer/domain/time_summary.dart';

class DashboardState {
  const DashboardState({
    required this.today,
    required this.thisWeek,
    required this.rankedTasks,
  });

  final TimeSummary today;
  final TimeSummary thisWeek;
  final List<TaskTimeSummary> rankedTasks;
}
