import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/services/database/app_database.dart';
import '../../../core/sync/sync_providers.dart';
import '../../authentication/data/auth_providers.dart';
import '../data/task_providers.dart';
import '../data/task_sync_providers.dart';
import '../../../core/sync/sync_controller.dart';

final taskControllerProvider =
    AsyncNotifierProvider<TaskController, List<Task>>(TaskController.new);

class TaskController extends AsyncNotifier<List<Task>> {
  @override
  Future<List<Task>> build() async {
    ref.watch(authStateChangesProvider);

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
    final authRepository = ref.read(authRepositoryProvider);
    final user = authRepository.currentUser;

    if (user == null) {
      return Future.value([]);
    }

    final repository = ref.read(taskRepositoryProvider);

    return repository.getTasks(user.uid);
  }

  Future<void> createTask({required String name, String? description}) async {
    if (name.trim().isEmpty) {
      state = AsyncError(
        const ValidationException('Task name cannot be empty.'),
        StackTrace.current,
      );

      return;
    }

    final authRepository = ref.read(authRepositoryProvider);
    final user = authRepository.currentUser;

    if (user == null) {
      state = AsyncError(
        const ValidationException('You must be signed in to create a task.'),
        StackTrace.current,
      );

      return;
    }

    try {
      final repository = ref.read(taskRepositoryProvider);

      final syncId = ref.read(syncIdGeneratorProvider).generate();

      await repository.createTask(
        name: name.trim(),
        description: description,
        syncId: syncId,
        userId: user.uid,
      );

      AppLogger.info('Task created: ${name.trim()}');

      AnalyticsService.instance.logEvent('task_created');

      state = AsyncData(await _loadTasks());
      try {
        await ref.read(taskSyncServiceProvider).syncTasks(user.uid);
      } catch (error, stackTrace) {
        AppLogger.error(
          'Failed to sync tasks',
          error: error,
          stackTrace: stackTrace,
        );
      }
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

  Future<void> refresh() async {
    final user = ref.read(authRepositoryProvider).currentUser;

    if (user == null) {
      return;
    }

    try {
      await ref.read(syncControllerProvider.notifier).sync();

      state = AsyncData(await _loadTasks());
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to refresh tasks',
        error: error,
        stackTrace: stackTrace,
      );

      state = AsyncError(ErrorHandler.handle(error, stackTrace), stackTrace);
    }
  }
}
