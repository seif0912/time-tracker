import 'package:drift/drift.dart';
import '../../../core/services/database/app_database.dart';
import '../../../core/sync/sync_status.dart';
import '../domain/history_entry.dart';
import '../domain/time_summary.dart';
import '../domain/recently_tracked_task.dart';
import '../../home/domain/today_time_stats.dart';

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
      leftOuterJoin(
        database.tasks,
        database.tasks.id.equalsExp(database.timeEntries.taskId),
      ),
    ]);

    query.where(
      database.timeEntries.userId.equals(userId) &
          database.timeEntries.deletedAt.isNull(),
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
      final task = row.readTableOrNull(database.tasks);

      return HistoryEntry(
        taskId: entry.taskId,
        taskName: task?.name ?? 'Deleted task',
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

  Future<TimeEntry?> getTimeEntryBySyncId(String syncId) {
    return (database.select(
      database.timeEntries,
    )..where((entry) => entry.syncId.equals(syncId))).getSingleOrNull();
  }

  Future<void> insertRemoteTimeEntry({
    required String syncId,
    required String userId,
    required int taskId,
    required DateTime startedAt,
    required DateTime? endedAt,
    required int? durationSeconds,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) async {
    await database
        .into(database.timeEntries)
        .insert(
          TimeEntriesCompanion.insert(
            syncId: syncId,
            userId: userId,
            taskId: taskId,
            startedAt: startedAt,
            endedAt: Value(endedAt),
            durationSeconds: Value(durationSeconds),
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: SyncStatus.synced.name,
            deletedAt: Value(deletedAt),
          ),
        );
  }

  Future<void> updateFromRemote({
    required int id,
    required int taskId,
    required DateTime startedAt,
    required DateTime? endedAt,
    required int? durationSeconds,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) async {
    await (database.update(
      database.timeEntries,
    )..where((entry) => entry.id.equals(id))).write(
      TimeEntriesCompanion(
        taskId: Value(taskId),
        startedAt: Value(startedAt),
        endedAt: Value(endedAt),
        durationSeconds: Value(durationSeconds),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
        deletedAt: Value(deletedAt),
        syncStatus: Value(SyncStatus.synced.name),
      ),
    );
  }

  Future<List<RecentlyTrackedTask>> getRecentlyTrackedTasks({
    required String userId,
    int limit = 3,
  }) async {
    final query = database.select(database.timeEntries).join([
      innerJoin(
        database.tasks,
        database.tasks.id.equalsExp(database.timeEntries.taskId),
      ),
    ]);

    query
      ..where(
        database.timeEntries.userId.equals(userId) &
            database.timeEntries.deletedAt.isNull() &
            database.tasks.archived.equals(false) &
            database.tasks.deletedAt.isNull(),
      )
      ..orderBy([
        OrderingTerm(
          expression: database.timeEntries.startedAt,
          mode: OrderingMode.desc,
        ),
      ]);

    final rows = await query.get();

    final grouped = <int, RecentlyTrackedTask>{};

    for (final row in rows) {
      final entry = row.readTable(database.timeEntries);
      final task = row.readTable(database.tasks);

      final existing = grouped[task.id];

      if (existing == null) {
        grouped[task.id] = RecentlyTrackedTask(
          taskId: task.id,
          taskName: task.name,
          category: task.category,
          lastTrackedAt: entry.startedAt,
          totalDurationSeconds: entry.durationSeconds ?? 0,
          sessionCount: 1,
        );
      } else {
        grouped[task.id] = RecentlyTrackedTask(
          taskId: existing.taskId,
          taskName: existing.taskName,
          category: existing.category,
          lastTrackedAt: existing.lastTrackedAt,
          totalDurationSeconds:
              existing.totalDurationSeconds + (entry.durationSeconds ?? 0),
          sessionCount: existing.sessionCount + 1,
        );
      }
    }

    return grouped.values.take(limit).toList();
  }

  Future<void> createTimeEntrySegment({
    required String userId,
    required int taskId,
    required DateTime startedAt,
    required DateTime endedAt,
    required int durationSeconds,
  }) async {
    if (durationSeconds <= 0) return;

    await database
        .into(database.timeEntrySegments)
        .insert(
          TimeEntrySegmentsCompanion.insert(
            userId: userId,
            taskId: taskId,
            startedAt: startedAt,
            endedAt: endedAt,
            durationSeconds: durationSeconds,
          ),
        );
  }

  Future<TimeEntry> completeTimeEntry({
    required int taskId,
    required String syncId,
    required String userId,
    required DateTime startedAt,
    required DateTime endedAt,
    required int durationSeconds,
    DateTime? segmentStartedAt,
    int segmentDurationSeconds = 0,
  }) async {
    final now = DateTime.now();
    late int id;

    await database.transaction(() async {
      if (segmentStartedAt != null && segmentDurationSeconds > 0) {
        await createTimeEntrySegment(
          userId: userId,
          taskId: taskId,
          startedAt: segmentStartedAt,
          endedAt: endedAt,
          durationSeconds: segmentDurationSeconds,
        );
      }

      id = await database
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
    });

    return (database.select(
      database.timeEntries,
    )..where((entry) => entry.id.equals(id))).getSingle();
  }

  Future<TodayTimeStats> getTodayStats({
    required String userId,
    required DateTime now,
    required DateTime dayStart,
    DateTime? runningSegmentStartedAt,
  }) async {
    final segments =
        await (database.select(database.timeEntrySegments)..where(
              (segment) =>
                  segment.userId.equals(userId) &
                  segment.startedAt.isSmallerThanValue(now) &
                  segment.endedAt.isBiggerThanValue(dayStart),
            ))
            .get();

    final hourlySeconds = List<int>.filled(24, 0);

    void addInterval(DateTime segmentStart, DateTime segmentEnd) {
      final start = segmentStart.isBefore(dayStart) ? dayStart : segmentStart;

      final end = segmentEnd.isAfter(now) ? now : segmentEnd;

      if (!end.isAfter(start)) return;

      for (var hour = 0; hour < 24; hour++) {
        final hourStart = dayStart.add(Duration(hours: hour));
        final hourEnd = hourStart.add(const Duration(hours: 1));

        final overlapStart = start.isAfter(hourStart) ? start : hourStart;
        final overlapEnd = end.isBefore(hourEnd) ? end : hourEnd;

        if (overlapEnd.isAfter(overlapStart)) {
          hourlySeconds[hour] += overlapEnd.difference(overlapStart).inSeconds;
        }
      }
    }

    for (final segment in segments) {
      addInterval(segment.startedAt, segment.endedAt);
    }

    // The running segment has not been persisted yet, so include it live.
    if (runningSegmentStartedAt != null) {
      addInterval(runningSegmentStartedAt, now);
    }

    return TodayTimeStats(
      totalSeconds: hourlySeconds.fold<int>(0, (sum, seconds) => sum + seconds),
      hourlySeconds: hourlySeconds,
    );
  }
}
