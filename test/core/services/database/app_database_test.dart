import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:time_tracker/core/services/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('creates the current schema successfully', () async {
    expect(database.schemaVersion, 5);

    final tasks = await database.select(database.tasks).get();
    final timeEntries = await database.select(database.timeEntries).get();
    final profiles = await database.select(database.userProfiles).get();
    final activeTimers = await database.select(database.activeTimers).get();

    expect(tasks, isEmpty);
    expect(timeEntries, isEmpty);
    expect(profiles, isEmpty);
    expect(activeTimers, isEmpty);
  });
}
