import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/database/database_provider.dart';
import 'task_repository.dart';

import '../../../core/services/database/app_database.dart';
import '../../authentication/data/current_user_id_provider.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final database = ref.watch(databaseProvider);

  return TaskRepository(database);
});

final userTasksProvider = FutureProvider<List<Task>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return [];
  }

  final repository = ref.watch(taskRepositoryProvider);
  return repository.getTasks(userId);
});
