import 'package:drift/drift.dart';

import '../../../core/services/database/app_database.dart';
import '../../../core/sync/sync_status.dart';

class TimeEntryRepository {
  final AppDatabase database;

  TimeEntryRepository(this.database);

  Future<TimeEntry> createTimeEntry({
    required int taskId,
    required String syncId,
    required String userId,
    required DateTime startedAt,
    required DateTime endedAt,
    required int durationSeconds,
  }) async {
    final now = DateTime.now();

    final id = await database
        .into(database.timeEntries)
        .insert(
          TimeEntriesCompanion.insert(
            syncId: syncId,
            userId: userId,
            taskId: taskId,
            startedAt: startedAt,
            endedAt: Value(endedAt),
            durationSeconds: Value(durationSeconds),
            createdAt: now,
            updatedAt: now,
            syncStatus: SyncStatus.pendingCreate.name,
          ),
        );

    return (database.select(
      database.timeEntries,
    )..where((entry) => entry.id.equals(id))).getSingle();
  }

  Future<List<TimeEntry>> getEntriesForTask({
    required String userId,
    required int taskId,
  }) {
    return (database.select(database.timeEntries)
          ..where((entry) => entry.taskId.equals(taskId))
          ..orderBy([
            (entry) => OrderingTerm(
              expression: entry.startedAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  Future<List<TimeEntry>> getPendingSyncEntries(String userId) {
    return (database.select(database.timeEntries)..where(
          (entry) =>
              entry.userId.equals(userId) &
              entry.syncStatus.isNotValue(SyncStatus.synced.name),
        ))
        .get();
  }

  Future<void> markTimeEntryAsSynced(int id) {
    return (database.update(database.timeEntries)
          ..where((entry) => entry.id.equals(id)))
        .write(TimeEntriesCompanion(syncStatus: Value(SyncStatus.synced.name)));
  }
}
