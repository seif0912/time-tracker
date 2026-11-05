import 'package:drift/drift.dart';

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Globally unique identifier used for Firebase synchronization.
  TextColumn get syncId => text().unique()();

  /// Firebase Authentication UID that owns this task.
  TextColumn get userId => text()();

  TextColumn get name => text()();

  TextColumn get description => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  BoolColumn get favorite => boolean().withDefault(const Constant(false))();

  /// One of the values from SyncStatus.
  TextColumn get syncStatus => text()();

  /// Tombstone used when a task is deleted locally but still needs
  /// to be deleted from Firebase.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// Built-in category: work, study, personal, health,
  /// fitness, finance, or other.
  TextColumn get category => text().withDefault(const Constant('work'))();

  /// Hex color used to visually identify the task.
  TextColumn get color => text().withDefault(const Constant('#7143AC'))();

  /// Optional estimated task duration, in seconds.
  IntColumn get estimatedDurationSeconds => integer().nullable()();
}
