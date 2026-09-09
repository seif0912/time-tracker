import 'subscription_plan.dart';

class UserProfile {
  const UserProfile({
    required this.userId,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.plan = SubscriptionPlan.free,
    required this.createdAt,
    required this.updatedAt,
  });

  final String userId;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final SubscriptionPlan plan;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPro => plan == SubscriptionPlan.pro;

  UserProfile copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    SubscriptionPlan? plan,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      userId: userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      plan: plan ?? this.plan,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
