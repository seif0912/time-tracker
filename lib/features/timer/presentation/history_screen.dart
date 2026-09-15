import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import '../domain/history_entry.dart';
import '../domain/history_group.dart';
import 'history_controller.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.invalidate(historyControllerProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: history.when(
        loading: () {
          return const AppLoading(message: 'Loading history...');
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
                ref.invalidate(historyControllerProvider);
              },
            ),
          );
        },
        data: (groups) {
          if (groups.isEmpty) {
            return const AppEmptyState(
              icon: Icons.history_rounded,
              title: 'No history yet',
              description: 'Completed timer sessions will appear here.',
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(historyControllerProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];

                return _HistoryGroup(group: group);
              },
            ),
          );
        },
      ),
    );
  }
}

class _HistoryGroup extends StatelessWidget {
  const _HistoryGroup({required this.group});

  final HistoryGroup group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _formatGroupDate(group.date),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...group.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(child: _HistoryEntryTile(entry: entry)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatGroupDate(DateTime date) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'Today';
    }

    if (date == yesterday) {
      return 'Yesterday';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}

class _HistoryEntryTile extends StatelessWidget {
  const _HistoryEntryTile({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(entry.taskName, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          _formatDuration(entry.durationSeconds),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          '${_formatDateTime(entry.startedAt)} → '
          '${entry.endedAt == null ? 'In progress' : _formatDateTime(entry.endedAt!)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final remainingSeconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    }

    return '${remainingSeconds}s';
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();

    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '${local.day}/${local.month}/${local.year} '
        '$hour:$minute';
  }
}
