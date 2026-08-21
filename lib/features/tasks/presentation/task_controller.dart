import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_handler.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/services/database/app_database.dart';
import '../data/task_providers.dart';

import '../../../core/analytics/analytics_service.dart';

final taskControllerProvider =
    AsyncNotifierProvider<TaskController, List<Task>>(TaskController.new);

class TaskController extends AsyncNotifier<List<Task>> {
  @override
  Future<List<Task>> build() async {
    try {
      return await _loadTasks();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load tasks',
        error: error,
        stackTrace: stackTrace,
      );

      throw ErrorHandler.handle(error, stackTrace);
    }
  }

  Future<List<Task>> _loadTasks() {
    final repository = ref.read(taskRepositoryProvider);

    return repository.getTasks();
  }

  Future<void> createTask({required String name, String? description}) async {
    if (name.trim().isEmpty) {
      state = AsyncError(
        const ValidationException('Task name cannot be empty.'),
        StackTrace.current,
      );

      return;
    }

    try {
      final repository = ref.read(taskRepositoryProvider);

      await repository.createTask(name: name.trim(), description: description);

      AppLogger.info('Task created: ${name.trim()}');

      AnalyticsService.instance.logEvent('task_created');

      state = AsyncData(await _loadTasks());

      AppLogger.info('Task created: ${name.trim()}');

      state = AsyncData(await _loadTasks());
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to create task',
        error: error,
        stackTrace: stackTrace,
      );

      state = AsyncError(ErrorHandler.handle(error, stackTrace), stackTrace);
    }
  }

  Future<void> archiveTask(int id) async {
    try {
      final repository = ref.read(taskRepositoryProvider);

      await repository.archiveTask(id);

      AppLogger.info('Task archived: $id');

      state = AsyncData(await _loadTasks());
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to archive task: $id',
        error: error,
        stackTrace: stackTrace,
      );

      state = AsyncError(ErrorHandler.handle(error, stackTrace), stackTrace);
    }
  }
}
