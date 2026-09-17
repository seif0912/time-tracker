import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/tasks.dart';
import 'tables/time_entries.dart';
import 'tables/user_profiles.dart';
import 'tables/active_timers.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Tasks, TimeEntries, UserProfiles, ActiveTimers])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },

    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(userProfiles);
      }

      // Phase 1 sync schema.
      //
      // Development databases can be reset because this schema
      // introduces the authenticated ownership/synchronization model.
      if (from < 3) {
        await m.addColumn(tasks, tasks.syncId);
        await m.addColumn(tasks, tasks.userId);
        await m.addColumn(tasks, tasks.updatedAt);
        await m.addColumn(tasks, tasks.syncStatus);
        await m.addColumn(tasks, tasks.deletedAt);
      }
      if (from < 4) {
        await m.addColumn(tasks, tasks.favorite);
      }
      if (from < 5) {
        await m.createTable(activeTimers);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    return driftDatabase(name: 'time_tracker');
  });
}
