import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_sync_service.dart';
import 'sync_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return FirebaseSyncService();
});
