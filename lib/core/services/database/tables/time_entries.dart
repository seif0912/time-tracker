import 'package:drift/drift.dart';

class TimeEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get taskId => integer()();

  DateTimeColumn get startedAt => dateTime()();

  DateTimeColumn get endedAt => dateTime().nullable()();

  IntColumn get durationSeconds => integer().nullable()();
}
