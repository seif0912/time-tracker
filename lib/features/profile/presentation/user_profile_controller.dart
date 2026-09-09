import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_profile_providers.dart';
import '../data/local_user_profile_repository.dart';
import '../data/profile_providers.dart';
import '../data/user_profile_repository.dart';
import '../domain/user_profile.dart';
import '../../authentication/data/auth_providers.dart';

final userProfileControllerProvider =
    AsyncNotifierProvider<UserProfileController, UserProfile?>(
      UserProfileController.new,
    );

class UserProfileController extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final authState = ref.watch(authStateChangesProvider);

    if (!authState.hasValue || authState.value == null) {
      return null;
    }

    final user = authState.value!;

    final localRepository = ref.read(localUserProfileRepositoryProvider);

    final cloudRepository = ref.read(userProfileRepositoryProvider);

    // Load local data first.
    final localProfile = await localRepository.getProfile(user.uid);

    if (localProfile != null) {
      // Refresh from Firebase in the background.
      _syncFromCloud(
        userId: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
        cloudRepository: cloudRepository,
        localRepository: localRepository,
      );

      return localProfile;
    }

    // No local profile yet.
    final cloudProfile = await cloudRepository.getOrCreateProfile(
      userId: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );

    await localRepository.saveProfile(cloudProfile);

    return cloudProfile;
  }

  Future<void> _syncFromCloud({
    required String userId,
    required String email,
    required String? displayName,
    required String? photoUrl,
    required UserProfileRepository cloudRepository,
    required LocalUserProfileRepository localRepository,
  }) async {
    try {
      final cloudProfile = await cloudRepository.getOrCreateProfile(
        userId: userId,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
      );

      await localRepository.saveProfile(cloudProfile);

      state = AsyncData(cloudProfile);
    } catch (_) {
      // Offline or temporary network failure.
      // Keep using the local profile.
    }
  }
}
