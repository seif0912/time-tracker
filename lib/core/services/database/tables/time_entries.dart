import 'package:drift/drift.dart';

class TimeEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Globally unique identifier used for Firebase synchronization.
  TextColumn get syncId => text().unique()();

  /// Firebase Authentication UID that owns this time entry.
  TextColumn get userId => text()();

  /// Local Task ID.
  IntColumn get taskId => integer()();

  DateTimeColumn get startedAt => dateTime()();

  DateTimeColumn get endedAt => dateTime().nullable()();

  IntColumn get durationSeconds => integer().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  /// One of the values from SyncStatus.
  TextColumn get syncStatus => text()();

  /// Tombstone used when a time entry is deleted locally.
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
