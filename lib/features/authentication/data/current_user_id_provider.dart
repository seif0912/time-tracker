import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'current_user_provider.dart';

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.uid;
});
