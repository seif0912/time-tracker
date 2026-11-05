import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import '../../timer/domain/timer_state.dart';
import '../../timer/presentation/timer_controller.dart';
import 'task_controller.dart';
import '../../../core/services/database/app_database.dart';
import 'task_list_provider.dart';
import '../domain/task_sort_order.dart';

const _taskCategories = [
  'work',
  'study',
  'personal',
  'health',
  'fitness',
  'finance',
  'other',
];

const _taskColors = [
  '#7143AC',
  '#3B82F6',
  '#10B981',
  '#F59E0B',
  '#EF4444',
  '#EC4899',
  '#64748B',
];

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.invalidate(taskControllerProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskControllerProvider);
    final filteredTasks = ref.watch(filteredTasksProvider);
    final timerState = ref.watch(timerControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            tooltip: 'Sort tasks',
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortOptions(context, ref),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (query) {
                ref
                    .read(taskListViewControllerProvider.notifier)
                    .setSearchQuery(query);
              },
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    ref
                        .watch(taskListViewControllerProvider)
                        .searchQuery
                        .isNotEmpty
                    ? IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          ref
                              .read(taskListViewControllerProvider.notifier)
                              .clearSearch();
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
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
        data: (_) {
          if (filteredTasks.isEmpty) {
            final searchQuery = ref
                .read(taskListViewControllerProvider)
                .searchQuery
                .trim();

            if (searchQuery.isNotEmpty) {
              return AppEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No matching tasks',
                description: 'Try a different search term.',
                action: AppButton(
                  label: 'Clear Search',
                  icon: Icons.clear,
                  expanded: false,
                  onPressed: () {
                    ref
                        .read(taskListViewControllerProvider.notifier)
                        .clearSearch();
                  },
                ),
              );
            }

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
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                final session = timerState.sessionForTask(task.id);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      title: InkWell(
                        onTap: () => _editTask(context, ref, task),
                        child: Text(task.name),
                      ),
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: task.favorite
                                ? 'Remove from favorites'
                                : 'Add to favorites',
                            icon: Icon(
                              task.favorite
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                            ),
                            onPressed: () {
                              ref
                                  .read(taskControllerProvider.notifier)
                                  .toggleFavorite(task.id);
                            },
                          ),
                          _buildTimerControls(
                            context,
                            ref,
                            task.id,
                            session,
                            timerState,
                          ),
                        ],
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
    final result = await showDialog<_TaskEditResult>(
      context: context,
      builder: (_) => const _CreateTaskDialog(),
    );

    if (result == null) return;

    await ref
        .read(taskControllerProvider.notifier)
        .createTask(
          name: result.name,
          description: result.description,
          category: result.category,
          color: result.color,
          estimatedDurationSeconds: result.estimatedDurationSeconds,
        );
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

Future<void> _editTask(BuildContext context, WidgetRef ref, Task task) async {
  final result = await showDialog<_TaskEditResult>(
    context: context,
    builder: (dialogContext) {
      return _EditTaskDialog(task: task);
    },
  );

  if (result == null) {
    return;
  }

  await ref
      .read(taskControllerProvider.notifier)
      .updateTask(
        id: task.id,
        name: result.name,
        description: result.description,
        category: result.category,
        color: result.color,
        estimatedDurationSeconds: result.estimatedDurationSeconds,
      );
}

class _TaskEditResult {
  const _TaskEditResult({
    required this.name,
    required this.category,
    required this.color,
    this.description,
    this.estimatedDurationSeconds,
  });

  final String name;
  final String? description;
  final String category;
  final String color;
  final int? estimatedDurationSeconds;
}

class _CreateTaskDialog extends StatefulWidget {
  const _CreateTaskDialog();

  @override
  State<_CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<_CreateTaskDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimateController = TextEditingController();

  String _category = 'work';
  String _color = '#7143AC';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _estimateController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final minutes = int.tryParse(_estimateController.text.trim());

    Navigator.of(context).pop(
      _TaskEditResult(
        name: name,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: _category,
        color: _color,
        estimatedDurationSeconds: minutes != null && minutes > 0
            ? minutes * 60
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _TaskFormDialog(
      title: 'Create task',
      nameController: _nameController,
      descriptionController: _descriptionController,
      estimateController: _estimateController,
      category: _category,
      color: _color,
      onCategoryChanged: (value) => setState(() => _category = value),
      onColorChanged: (value) => setState(() => _color = value),
      onSubmit: _submit,
    );
  }
}

class _EditTaskDialog extends StatefulWidget {
  const _EditTaskDialog({required this.task});

  final Task task;

  @override
  State<_EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<_EditTaskDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _estimateController;

  late String _category;
  late String _color;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.task.name);
    _descriptionController = TextEditingController(
      text: widget.task.description ?? '',
    );
    _estimateController = TextEditingController(
      text: widget.task.estimatedDurationSeconds == null
          ? ''
          : (widget.task.estimatedDurationSeconds! / 60).round().toString(),
    );

    _category = widget.task.category;
    _color = widget.task.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _estimateController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final minutes = int.tryParse(_estimateController.text.trim());

    Navigator.of(context).pop(
      _TaskEditResult(
        name: name,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: _category,
        color: _color,
        estimatedDurationSeconds: minutes != null && minutes > 0
            ? minutes * 60
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _TaskFormDialog(
      title: 'Edit task',
      nameController: _nameController,
      descriptionController: _descriptionController,
      estimateController: _estimateController,
      category: _category,
      color: _color,
      onCategoryChanged: (value) => setState(() => _category = value),
      onColorChanged: (value) => setState(() => _color = value),
      onSubmit: _submit,
    );
  }
}

class _TaskFormDialog extends StatelessWidget {
  const _TaskFormDialog({
    required this.title,
    required this.nameController,
    required this.descriptionController,
    required this.estimateController,
    required this.category,
    required this.color,
    required this.onCategoryChanged,
    required this.onColorChanged,
    required this.onSubmit,
  });

  final String title;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController estimateController;
  final String category;
  final String color;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onColorChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _taskCategories
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value[0].toUpperCase() + value.substring(1)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onCategoryChanged(value);
              },
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Color',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _taskColors.map((hex) {
                final selected = hex == color;
                final colorValue = Color(
                  int.parse(hex.substring(1), radix: 16) | 0xFF000000,
                );

                return GestureDetector(
                  onTap: () => onColorChanged(hex),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: colorValue,
                    child: selected
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: estimateController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              decoration: const InputDecoration(
                labelText: 'Estimated duration',
                suffixText: 'minutes',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: onSubmit,
          child: Text(title == 'Create task' ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}

void _showSortOptions(BuildContext context, WidgetRef ref) {
  final currentSort = ref.read(taskListViewControllerProvider).sortOrder;

  showModalBottomSheet<void>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: RadioGroup<TaskSortOrder>(
          groupValue: currentSort,
          onChanged: (value) {
            if (value == null) return;

            ref
                .read(taskListViewControllerProvider.notifier)
                .setSortOrder(value);

            Navigator.of(context).pop();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: TaskSortOrder.values.map((sortOrder) {
              return RadioListTile<TaskSortOrder>(
                title: Text(_sortOrderLabel(sortOrder)),
                value: sortOrder,
              );
            }).toList(),
          ),
        ),
      );
    },
  );
}

String _sortOrderLabel(TaskSortOrder sortOrder) {
  switch (sortOrder) {
    case TaskSortOrder.newest:
      return 'Newest first';

    case TaskSortOrder.oldest:
      return 'Oldest first';

    case TaskSortOrder.nameAscending:
      return 'Name A–Z';

    case TaskSortOrder.nameDescending:
      return 'Name Z–A';
  }
}
