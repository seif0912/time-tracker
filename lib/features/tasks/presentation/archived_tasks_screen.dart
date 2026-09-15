import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'archived_tasks_provider.dart';
import 'task_controller.dart';

class ArchivedTasksScreen extends ConsumerStatefulWidget {
  const ArchivedTasksScreen({super.key});

  @override
  ConsumerState<ArchivedTasksScreen> createState() =>
      _ArchivedTasksScreenState();
}

class _ArchivedTasksScreenState extends ConsumerState<ArchivedTasksScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.invalidate(archivedTasksProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final archivedTasks = ref.watch(archivedTasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Archived Tasks')),
      body: archivedTasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Failed to load archived tasks: $error')),
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(child: Text('No archived tasks.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(archivedTasksProvider);
              await ref.read(archivedTasksProvider.future);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];

                return ListTile(
                  title: Text(task.name),
                  subtitle:
                      task.description == null || task.description!.isEmpty
                      ? null
                      : Text(task.description!),
                  trailing: IconButton(
                    tooltip: 'Restore',
                    icon: const Icon(Icons.unarchive),
                    onPressed: () async {
                      await ref
                          .read(taskControllerProvider.notifier)
                          .restoreTask(task.id);

                      ref.invalidate(archivedTasksProvider);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
