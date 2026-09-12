import 'package:cloud_firestore/cloud_firestore.dart';

import 'sync_service.dart';

class FirebaseSyncService implements SyncService {
  FirebaseSyncService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ignore: unused_field
  final FirebaseFirestore _firestore;

  @override
  Future<void> sync() async {
    await syncTasks();
  }

  @override
  Future<void> syncTasks() async {
    // Task synchronization will be implemented in the next step.
  }
}
