import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'task_controller.dart';

final archivedTasksProvider = FutureProvider((ref) async {
  return ref.read(taskControllerProvider.notifier).getArchivedTasks();
});
