import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'task_controller.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskControllerProvider);

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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: taskList.length,
            itemBuilder: (context, index) {
              final task = taskList[index];

              return AppCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  title: Text(task.name),
                  subtitle: task.description == null
                      ? null
                      : Text(task.description!),
                  trailing: IconButton(
                    icon: const Icon(Icons.archive_outlined),
                    onPressed: () {
                      ref
                          .read(taskControllerProvider.notifier)
                          .archiveTask(task.id);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
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
