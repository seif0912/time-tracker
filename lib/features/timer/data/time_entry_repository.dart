import 'package:drift/drift.dart';

import '../../../core/services/database/app_database.dart';

class TimeEntryRepository {
  final AppDatabase database;

  TimeEntryRepository(this.database);

  Future<TimeEntry> createTimeEntry({
    required int taskId,
    required DateTime startedAt,
    required DateTime endedAt,
    required int durationSeconds,
  }) async {
    final id = await database
        .into(database.timeEntries)
        .insert(
          TimeEntriesCompanion.insert(
            taskId: taskId,
            startedAt: startedAt,
            endedAt: Value(endedAt),
            durationSeconds: Value(durationSeconds),
          ),
        );

    return (database.select(
      database.timeEntries,
    )..where((entry) => entry.id.equals(id))).getSingle();
  }

  Future<List<TimeEntry>> getEntriesForTask(int taskId) {
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
}
