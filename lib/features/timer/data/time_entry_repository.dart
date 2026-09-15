import 'package:drift/drift.dart';
import '../../../core/services/database/app_database.dart';
import '../../../core/sync/sync_status.dart';
import '../domain/history_entry.dart';
import '../domain/time_summary.dart';

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

  Future<List<TimeEntry>> getEntriesForUser(String userId) {
    return (database.select(database.timeEntries)
          ..where(
            (entry) => entry.userId.equals(userId) & entry.deletedAt.isNull(),
          )
          ..orderBy([
            (entry) => OrderingTerm(
              expression: entry.startedAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  Future<List<TimeEntry>> getEntriesForTask({
    required String userId,
    required int taskId,
  }) {
    return (database.select(database.timeEntries)
          ..where(
            (entry) =>
                entry.userId.equals(userId) &
                entry.taskId.equals(taskId) &
                entry.deletedAt.isNull(),
          )
          ..orderBy([
            (entry) => OrderingTerm(
              expression: entry.startedAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  Future<List<TimeEntry>> getEntriesBetween({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) {
    return (database.select(database.timeEntries)
          ..where(
            (entry) =>
                entry.userId.equals(userId) &
                entry.startedAt.isBiggerOrEqualValue(start) &
                entry.startedAt.isSmallerThanValue(end) &
                entry.deletedAt.isNull(),
          )
          ..orderBy([
            (entry) => OrderingTerm(
              expression: entry.startedAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  Future<int> getTotalDurationForTask({
    required String userId,
    required int taskId,
  }) async {
    final entries = await getEntriesForTask(userId: userId, taskId: taskId);
    return entries.fold<int>(
      0,
      (total, entry) => total + (entry.durationSeconds ?? 0),
    );
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

  Future<List<HistoryEntry>> getHistoryForUser(String userId) async {
    final query = database.select(database.timeEntries).join([
      innerJoin(
        database.tasks,
        database.tasks.id.equalsExp(database.timeEntries.taskId),
      ),
    ]);
    query.where(
      database.timeEntries.userId.equals(userId) &
          database.timeEntries.deletedAt.isNull() &
          database.tasks.deletedAt.isNull() &
          database.tasks.userId.equals(userId),
    );
    query.orderBy([
      OrderingTerm(
        expression: database.timeEntries.startedAt,
        mode: OrderingMode.desc,
      ),
    ]);
    final rows = await query.get();
    return rows.map((row) {
      final entry = row.readTable(database.timeEntries);
      final task = row.readTable(database.tasks);
      return HistoryEntry(
        taskId: entry.taskId,
        taskName: task.name,
        startedAt: entry.startedAt,
        endedAt: entry.endedAt,
        durationSeconds: entry.durationSeconds ?? 0,
      );
    }).toList();
  }

  Future<TimeSummary> getSummaryBetween({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    final entries = await getEntriesBetween(
      userId: userId,
      start: start,
      end: end,
    );

    final totalSeconds = entries.fold<int>(
      0,
      (total, entry) => total + (entry.durationSeconds ?? 0),
    );

    return TimeSummary(
      totalSeconds: totalSeconds,
      sessionCount: entries.length,
    );
  }

  Future<Map<int, TimeSummary>> getSummariesForTasks({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    final entries = await getEntriesBetween(
      userId: userId,
      start: start,
      end: end,
    );

    final grouped = <int, List<TimeEntry>>{};

    for (final entry in entries) {
      grouped.putIfAbsent(entry.taskId, () => []).add(entry);
    }

    return {
      for (final entry in grouped.entries)
        entry.key: TimeSummary(
          totalSeconds: entry.value.fold<int>(
            0,
            (total, timeEntry) => total + (timeEntry.durationSeconds ?? 0),
          ),
          sessionCount: entry.value.length,
        ),
    };
  }
}
