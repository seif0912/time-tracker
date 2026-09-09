import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firestore_user_profile_repository.dart';
import 'user_profile_repository.dart';

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return FirestoreUserProfileRepository();
});
