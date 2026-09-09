import '../domain/user_profile.dart';

abstract interface class UserProfileRepository {
  Future<UserProfile?> getProfile(String userId);

  Future<void> createProfile(UserProfile profile);

  Future<void> updateProfile(UserProfile profile);

  Future<UserProfile> getOrCreateProfile({
    required String userId,
    required String email,
    String? displayName,
    String? photoUrl,
  });
}
