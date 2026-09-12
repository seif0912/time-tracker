import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'task_providers.dart';
import 'task_sync_service.dart' show TaskSyncService;

final taskSyncServiceProvider = Provider<TaskSyncService>((ref) {
  return TaskSyncService(taskRepository: ref.read(taskRepositoryProvider));
});
