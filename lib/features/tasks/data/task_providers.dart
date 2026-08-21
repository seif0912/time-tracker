import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/database/database_provider.dart';
import 'task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final database = ref.watch(databaseProvider);

  return TaskRepository(database);
});
