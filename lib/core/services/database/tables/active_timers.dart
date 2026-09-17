import 'package:drift/drift.dart';

class ActiveTimers extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get userId => text()();

  IntColumn get taskId => integer()();

  TextColumn get status => text()();

  DateTimeColumn get startedAt => dateTime()();

  DateTimeColumn get currentSegmentStartedAt => dateTime().nullable()();

  IntColumn get accumulatedSeconds =>
      integer().withDefault(const Constant(0))();

  DateTimeColumn get updatedAt => dateTime()();
}
