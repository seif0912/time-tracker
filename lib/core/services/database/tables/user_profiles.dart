import 'package:drift/drift.dart';

class UserProfiles extends Table {
  TextColumn get userId => text()();

  TextColumn get email => text()();

  TextColumn get displayName => text().nullable()();

  TextColumn get photoUrl => text().nullable()();

  TextColumn get plan => text()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}
