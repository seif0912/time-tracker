import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/user_profiles.dart';

import 'tables/tasks.dart';
import 'tables/time_entries.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Tasks, TimeEntries, UserProfiles])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(userProfiles);
      }
    },
  );
}

DatabaseConnection _openConnection() {
  return driftDatabase(
    name: 'time_tracker',
    native: DriftNativeOptions(shareAcrossIsolates: true),
  );
}
