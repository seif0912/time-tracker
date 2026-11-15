import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../tasks/data/task_providers.dart';
import '../../timer/data/time_entry_providers.dart';
import '../../timer/domain/timer_state.dart';
import '../../timer/presentation/timer_controller.dart';
import 'providers/today_time_stats_provider.dart';
import 'widgets/home_timer_widget.dart';
import 'widgets/home_quick_actions.dart';
import 'widgets/home_recent_entries.dart';
import 'widgets/home_today_overview.dart';
import 'widgets/home_ai_insights.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int? _selectedTaskId;

  static const int _dailyGoalSeconds = 12 * 60 * 60;

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerControllerProvider);
    final tasksAsync = ref.watch(userTasksProvider);
    final recentTasksAsync = ref.watch(recentlyTrackedTasksProvider);
    final todayStatsAsync = ref.watch(todayTimeStatsProvider);

    final timerController = ref.read(timerControllerProvider.notifier);

    final tasks = tasksAsync.asData?.value ?? [];
    final recentTasks = recentTasksAsync.asData?.value ?? [];

    // ---------------------------------------------------------------
    // Timer and task selection
    // ---------------------------------------------------------------

    // An active or paused session always takes priority.
    final runningSession = timerState.runningSession;

    final pausedSessions =
        timerState.sessions.values
            .where((session) => session.status == TimerStatus.paused)
            .toList()
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    final selectedSession =
        runningSession ??
        (pausedSessions.isNotEmpty ? pausedSessions.first : null);

    // Retain the last explicitly selected task when no session exists.
    final selectedTaskId = selectedSession?.taskId ?? _selectedTaskId;

    final selectedTask = selectedTaskId != null
        ? tasks.where((task) => task.id == selectedTaskId).firstOrNull
        : null;

    final taskToDisplay =
        selectedTask ??
        (selectedSession == null && _selectedTaskId == null && tasks.isNotEmpty
            ? tasks.first
            : null);

    final isRunning = selectedSession?.status == TimerStatus.running;
    final isPaused = selectedSession?.status == TimerStatus.paused;

    final elapsedSeconds = selectedSession?.totalElapsedSeconds ?? 0;

    // A paused session also blocks starting another task.
    final hasAnySession = timerState.sessions.isNotEmpty;

    // ---------------------------------------------------------------
    // Recently tracked tasks
    // ---------------------------------------------------------------

    final recentItems = recentTasks.map((task) {
      return RecentTimeEntryItem(
        taskId: task.taskId,
        taskName: task.taskName,
        categoryName: task.category,
        icon: _categoryIcon(task.category),
        totalDuration: _formatDuration(task.totalDurationSeconds),
        onResume: hasAnySession
            ? null
            : () {
                setState(() {
                  _selectedTaskId = task.taskId;
                });

                timerController.start(taskId: task.taskId);
              },
      );
    }).toList();

    // ---------------------------------------------------------------
    // Today's analytics
    // ---------------------------------------------------------------

    final todayStats = todayStatsAsync.asData?.value;

    final todayTotalSeconds = todayStats?.totalSeconds ?? 0;

    final hourlySeconds = todayStats?.hourlySeconds ?? List<int>.filled(24, 0);

    // Normalize hourly activity against the busiest hour.
    // This keeps the busiest bar at full height.
    final maxHourlySeconds = hourlySeconds.fold<int>(
      0,
      (maximum, seconds) => seconds > maximum ? seconds : maximum,
    );

    final hourlyActivity = hourlySeconds.map((seconds) {
      if (maxHourlySeconds == 0) return 0.0;

      return seconds / maxHourlySeconds;
    }).toList();

    final todayProgress = (todayTotalSeconds / _dailyGoalSeconds)
        .clamp(0.0, 1.0)
        .toDouble();

    // ---------------------------------------------------------------
    // UI
    // ---------------------------------------------------------------

    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            AppPageHeader(
              title: 'Good Morning',
              subtitle: 'Small Steps, Big Progress.',
              titleStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              subtitleStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              onSettingsTap: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Timer
                    HomeTimerWidget(
                      taskName:
                          taskToDisplay?.name ??
                          (tasksAsync.isLoading
                              ? 'Loading tasks...'
                              : 'No tasks yet'),
                      taskIcon: _categoryIcon(taskToDisplay?.category),
                      elapsedTime: _formatClockDuration(elapsedSeconds),
                      isRunning: isRunning,
                      isPaused: isPaused,
                      onToggle: taskToDisplay == null
                          ? null
                          : () {
                              setState(() {
                                _selectedTaskId = taskToDisplay.id;
                              });

                              if (isPaused) {
                                timerController.resume(taskToDisplay.id);
                              } else {
                                timerController.start(taskId: taskToDisplay.id);
                              }
                            },
                      onPause: taskToDisplay == null
                          ? null
                          : () => timerController.pause(taskToDisplay.id),
                      onStop: taskToDisplay == null
                          ? null
                          : () async {
                              // Keep this task selected after stopping.
                              setState(() {
                                _selectedTaskId = taskToDisplay.id;
                              });

                              await timerController.stop(taskToDisplay.id);

                              ref.invalidate(recentlyTrackedTasksProvider);

                              ref.invalidate(todayTimeStatsProvider);
                            },
                    ),

                    const SizedBox(height: 16),

                    // Quick actions
                    HomeQuickActions(
                      onAddTask: () {},
                      onAddTime: () {},
                      onSwitchTask: () {},
                      onMore: () {},
                    ),

                    const SizedBox(height: 16),

                    // Recently tracked tasks
                    HomeRecentEntries(entries: recentItems, onViewAll: () {}),

                    const SizedBox(height: 16),

                    // Today's real tracking statistics
                    HomeTodayOverview(
                      totalTime: _formatClockHoursMinutes(todayTotalSeconds),
                      goalTime: '12h',
                      progress: todayProgress,
                      hourlyActivity: hourlyActivity,
                    ),

                    const SizedBox(height: 16),

                    // AI Insights
                    HomeAiInsights(onTap: () => context.push('/upgrade')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Formatting helpers
  // ---------------------------------------------------------------

  static String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m';

    return '${totalSeconds}s';
  }

  static String _formatClockDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  static String _formatClockHoursMinutes(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}';
  }

  static IconData _categoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'development':
      case 'programming':
      case 'coding':
        return Icons.code_rounded;

      case 'design':
        return Icons.brush_outlined;

      case 'study':
      case 'learning':
        return Icons.school_outlined;

      case 'personal':
        return Icons.person_outline_rounded;

      case 'work':
      default:
        return Icons.work_outline_rounded;
    }
  }
}
