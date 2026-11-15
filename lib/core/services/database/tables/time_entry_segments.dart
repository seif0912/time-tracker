import 'package:drift/drift.dart';

class TimeEntrySegments extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Firebase Authentication UID that owns this segment.
  TextColumn get userId => text()();

  /// Local Task ID.
  IntColumn get taskId => integer()();

  /// Exact start of this continuous tracking segment.
  DateTimeColumn get startedAt => dateTime()();

  /// Exact end of this continuous tracking segment.
  DateTimeColumn get endedAt => dateTime()();

  /// Actual tracked duration, excluding paused time.
  IntColumn get durationSeconds => integer()();
}
