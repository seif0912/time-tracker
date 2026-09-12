import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import '../../timer/domain/timer_state.dart';
import '../../timer/presentation/timer_controller.dart';
import 'task_controller.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskControllerProvider);
    final timerState = ref.watch(timerControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createTask(context, ref),
        child: const Icon(Icons.add),
      ),
      body: tasks.when(
        loading: () {
          return const AppLoading(message: 'Loading tasks...');
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
                ref.invalidate(taskControllerProvider);
              },
            ),
          );
        },
        data: (taskList) {
          if (taskList.isEmpty) {
            return AppEmptyState(
              icon: Icons.task_alt_rounded,
              title: 'No tasks yet',
              description:
                  'Create your first task to start tracking your time.',
              action: AppButton(
                label: 'Create Task',
                icon: Icons.add,
                expanded: false,
                onPressed: () => _createTask(context, ref),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(taskControllerProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: taskList.length,
              itemBuilder: (context, index) {
                final task = taskList[index];
                final session = timerState.sessionForTask(task.id);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      title: Text(task.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (task.description != null) Text(task.description!),
                          if (session != null) ...[
                            const SizedBox(height: 4),
                            Text(_formatDuration(session.totalElapsedSeconds)),
                          ],
                        ],
                      ),
                      trailing: _buildTimerControls(
                        context,
                        ref,
                        task.id,
                        session,
                        timerState,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimerControls(
    BuildContext context,
    WidgetRef ref,
    int taskId,
    TimerSessionState? session,
    TimerState timerState,
  ) {
    final controller = ref.read(timerControllerProvider.notifier);

    // No session for this task.
    if (session == null) {
      final hasRunningSession = timerState.hasRunningSession;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: hasRunningSession
                ? 'Another timer is running'
                : 'Start timer',
            icon: const Icon(Icons.play_arrow_rounded),
            onPressed: hasRunningSession
                ? null
                : () {
                    controller.start(taskId: taskId);
                  },
          ),
          IconButton(
            tooltip: 'Archive',
            icon: const Icon(Icons.archive_outlined),
            onPressed: () {
              ref.read(taskControllerProvider.notifier).archiveTask(taskId);
            },
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () {
              _confirmDelete(context, ref, taskId);
            },
          ),
        ],
      );
    }

    // This task is currently running.
    if (session.status == TimerStatus.running) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Pause',
            icon: const Icon(Icons.pause_rounded),
            onPressed: () {
              controller.pause(taskId);
            },
          ),
          IconButton(
            tooltip: 'Stop',
            icon: const Icon(Icons.stop_rounded),
            onPressed: () async {
              await controller.stop(taskId);
            },
          ),
        ],
      );
    }

    // This task is paused.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Resume',
          icon: const Icon(Icons.play_arrow_rounded),
          onPressed: timerState.hasRunningSession
              ? null
              : () {
                  controller.resume(taskId);
                },
        ),
        IconButton(
          tooltip: 'Stop',
          icon: const Icon(Icons.stop_rounded),
          onPressed: () async {
            await controller.stop(taskId);
          },
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final remainingSeconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _createTask(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return const _CreateTaskDialog();
      },
    );

    if (name == null || name.trim().isEmpty) {
      return;
    }

    await ref
        .read(taskControllerProvider.notifier)
        .createTask(name: name.trim());
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  int taskId,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Delete task?'),
        content: const Text(
          'This task will be removed from your active tasks. '
          'Recorded time will be preserved for your history and insights.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );

  if (confirmed != true) {
    return;
  }

  await ref.read(taskControllerProvider.notifier).deleteTask(taskId);
}

class _CreateTaskDialog extends StatefulWidget {
  const _CreateTaskDialog();

  @override
  State<_CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<_CreateTaskDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();

    if (name.isEmpty) {
      return;
    }

    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create task'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(hintText: 'Task name'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }
}
