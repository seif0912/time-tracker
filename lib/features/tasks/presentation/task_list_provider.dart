import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/database/app_database.dart';
import '../domain/task_sort_order.dart';
import 'task_controller.dart';

class TaskListViewState {
  const TaskListViewState({
    this.searchQuery = '',
    this.sortOrder = TaskSortOrder.newest,
  });

  final String searchQuery;
  final TaskSortOrder sortOrder;

  TaskListViewState copyWith({String? searchQuery, TaskSortOrder? sortOrder}) {
    return TaskListViewState(
      searchQuery: searchQuery ?? this.searchQuery,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class TaskListViewController extends Notifier<TaskListViewState> {
  @override
  TaskListViewState build() {
    return const TaskListViewState();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSortOrder(TaskSortOrder sortOrder) {
    state = state.copyWith(sortOrder: sortOrder);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }
}

final taskListViewControllerProvider =
    NotifierProvider<TaskListViewController, TaskListViewState>(
      TaskListViewController.new,
    );

final filteredTasksProvider = Provider<List<Task>>((ref) {
  final tasksAsync = ref.watch(taskControllerProvider);
  final viewState = ref.watch(taskListViewControllerProvider);

  return tasksAsync.when(
    loading: () => <Task>[],
    error: (_, _) => <Task>[],
    data: (tasks) {
      final searchQuery = viewState.searchQuery.trim().toLowerCase();

      final filtered = searchQuery.isEmpty
          ? [...tasks]
          : tasks.where((task) {
              final name = task.name.toLowerCase();
              final description = task.description?.toLowerCase() ?? '';

              return name.contains(searchQuery) ||
                  description.contains(searchQuery);
            }).toList();

      switch (viewState.sortOrder) {
        case TaskSortOrder.newest:
          filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        case TaskSortOrder.oldest:
          filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        case TaskSortOrder.nameAscending:
          filtered.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

        case TaskSortOrder.nameDescending:
          filtered.sort(
            (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
          );
      }

      return filtered;
    },
  );
});
