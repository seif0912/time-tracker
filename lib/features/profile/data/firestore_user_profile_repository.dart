import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/subscription_plan.dart';
import '../domain/user_profile.dart';
import 'user_profile_repository.dart';

class FirestoreUserProfileRepository implements UserProfileRepository {
  FirestoreUserProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<UserProfile?> getProfile(String userId) async {
    final snapshot = await _users.doc(userId).get();

    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data();

    if (data == null) {
      return null;
    }

    return UserProfile(
      userId: userId,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      plan: SubscriptionPlan.fromString(data['plan'] as String?),
      createdAt: _readDateTime(data['createdAt']),
      updatedAt: _readDateTime(data['updatedAt']),
    );
  }

  @override
  Future<UserProfile> getOrCreateProfile({
    required String userId,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    final existingProfile = await getProfile(userId);

    if (existingProfile != null) {
      return existingProfile;
    }

    final now = DateTime.now();

    final profile = UserProfile(
      userId: userId,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      plan: SubscriptionPlan.free,
      createdAt: now,
      updatedAt: now,
    );

    await createProfile(profile);

    return profile;
  }

  @override
  Future<void> createProfile(UserProfile profile) async {
    await _users.doc(profile.userId).set({
      'email': profile.email,
      'displayName': profile.displayName,
      'photoUrl': profile.photoUrl,
      'plan': profile.plan.value,
      'createdAt': Timestamp.fromDate(profile.createdAt),
      'updatedAt': Timestamp.fromDate(profile.updatedAt),
    });
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    await _users.doc(profile.userId).set({
      'email': profile.email,
      'displayName': profile.displayName,
      'photoUrl': profile.photoUrl,
      'plan': profile.plan.value,
      'updatedAt': Timestamp.fromDate(profile.updatedAt),
    }, SetOptions(merge: true));
  }

  DateTime _readDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
