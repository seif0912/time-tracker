import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/data/current_user_id_provider.dart';

import '../../../core/services/database/database_provider.dart';
import 'time_entry_repository.dart';
import '../domain/recently_tracked_task.dart';

final timeEntryRepositoryProvider = Provider<TimeEntryRepository>((ref) {
  final database = ref.watch(databaseProvider);

  return TimeEntryRepository(database);
});

final recentlyTrackedTasksProvider = FutureProvider<List<RecentlyTrackedTask>>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return [];

  return ref
      .watch(timeEntryRepositoryProvider)
      .getRecentlyTrackedTasks(userId: userId, limit: 3);
});
