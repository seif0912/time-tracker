import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tasks/data/task_providers.dart';
import 'time_entry_providers.dart';
import 'time_entry_sync_service.dart';

final timeEntrySyncServiceProvider = Provider<TimeEntrySyncService>((ref) {
  return TimeEntrySyncService(
    timeEntryRepository: ref.read(timeEntryRepositoryProvider),
    taskRepository: ref.read(taskRepositoryProvider),
  );
});
