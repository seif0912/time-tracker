import 'package:drift/drift.dart';

import '../../../core/services/database/app_database.dart' as db;
import '../domain/subscription_plan.dart';
import '../domain/user_profile.dart';

class LocalUserProfileRepository {
  LocalUserProfileRepository(this.database);

  final db.AppDatabase database;

  Future<UserProfile?> getProfile(String userId) async {
    final row = await (database.select(
      database.userProfiles,
    )..where((profile) => profile.userId.equals(userId))).getSingleOrNull();

    if (row == null) {
      return null;
    }

    return _toDomain(row);
  }

  Future<void> saveProfile(UserProfile profile) async {
    await database
        .into(database.userProfiles)
        .insertOnConflictUpdate(
          db.UserProfilesCompanion(
            userId: Value(profile.userId),
            email: Value(profile.email),
            displayName: Value(profile.displayName),
            photoUrl: Value(profile.photoUrl),
            plan: Value(profile.plan.value),
            createdAt: Value(profile.createdAt),
            updatedAt: Value(profile.updatedAt),
          ),
        );
  }

  UserProfile _toDomain(db.UserProfile row) {
    return UserProfile(
      userId: row.userId,
      email: row.email,
      displayName: row.displayName,
      photoUrl: row.photoUrl,
      plan: SubscriptionPlan.fromString(row.plan),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
