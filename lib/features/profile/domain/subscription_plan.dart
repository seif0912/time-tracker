enum SubscriptionPlan {
  free,
  pro;

  static SubscriptionPlan fromString(String? value) {
    switch (value) {
      case 'pro':
        return SubscriptionPlan.pro;
      case 'free':
      default:
        return SubscriptionPlan.free;
    }
  }

  String get value => name;
}
