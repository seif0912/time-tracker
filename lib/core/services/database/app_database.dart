import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/tasks.dart';
import 'tables/time_entries.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Tasks, TimeEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

DatabaseConnection _openConnection() {
  return driftDatabase(
    name: 'time_tracker',
    native: DriftNativeOptions(shareAcrossIsolates: true),
  );
}
