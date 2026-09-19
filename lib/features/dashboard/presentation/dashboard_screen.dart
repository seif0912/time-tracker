import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import '../../timer/domain/time_summary.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: dashboard.when(
        loading: () {
          return const AppLoading(message: 'Loading dashboard...');
        },
        error: (error, stackTrace) {
          return AppEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Something went wrong',
            description: error.toString(),
            action: AppButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              expanded: false,
              onPressed: () {
                ref.invalidate(dashboardControllerProvider);
              },
            ),
          );
        },
        data: (data) {
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(dashboardControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryCard(title: 'Today', summary: data.today),
                const SizedBox(height: 16),
                _SummaryCard(title: 'This week', summary: data.thisWeek),
                const SizedBox(height: 24),
                Text(
                  'Time by task',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (data.rankedTasks.isEmpty)
                  const AppEmptyState(
                    icon: Icons.timer_outlined,
                    title: 'No tracked time yet',
                    description:
                        'Complete a timer session to see your task breakdown.',
                  )
                else
                  ...data.rankedTasks.map((taskSummary) {
                    final taskName =
                        data.taskNames[taskSummary.taskId] ?? 'Deleted task';

                    return AppCard(
                      child: ListTile(
                        title: Text(taskName),
                        subtitle: Text(
                          '${taskSummary.sessionCount} '
                          '${taskSummary.sessionCount == 1 ? 'session' : 'sessions'}',
                        ),
                        trailing: Text(
                          _formatDuration(taskSummary.totalSeconds),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    if (minutes > 0) {
      return '${minutes}m';
    }

    return '${duration.inSeconds}s';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.summary});

  final String title;
  final TimeSummary summary;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            _formatDuration(summary.totalSeconds),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${summary.sessionCount} '
            '${summary.sessionCount == 1 ? 'session' : 'sessions'}',
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    if (minutes > 0) {
      return '${minutes}m';
    }

    return '${duration.inSeconds}s';
  }
}
