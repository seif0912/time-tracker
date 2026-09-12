import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/database/app_database.dart';
import 'task_repository.dart';
import '../../../core/sync/sync_status.dart';

class TaskSyncService {
  TaskSyncService({required this._taskRepository, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final TaskRepository _taskRepository;
  final FirebaseFirestore _firestore;

  Future<void> syncTasks(String userId) async {
    // Push local changes first.
    final pendingTasks = await _taskRepository.getPendingSyncTasks(userId);

    for (final task in pendingTasks) {
      await _syncTask(task);
    }

    // Pull remote changes afterwards.
    await _pullRemoteTasks(userId);
  }

  Future<void> _syncTask(Task task) async {
    final document = _firestore
        .collection('users')
        .doc(task.userId)
        .collection('tasks')
        .doc(task.syncId);

    final data = <String, dynamic>{
      'syncId': task.syncId,
      'userId': task.userId,
      'name': task.name,
      'description': task.description,
      'createdAt': Timestamp.fromDate(task.createdAt),
      'updatedAt': Timestamp.fromDate(task.updatedAt),
      'archived': task.archived,
      'deletedAt': task.deletedAt == null
          ? null
          : Timestamp.fromDate(task.deletedAt!),
    };

    switch (task.syncStatus) {
      case 'pendingCreate':
      case 'pendingUpdate':
        await document.set(data);
        await _taskRepository.markTaskAsSynced(task.id);

      case 'pendingDelete':
        final deletedAt = task.deletedAt;

        if (deletedAt == null) {
          throw StateError('Deleted task ${task.syncId} is missing deletedAt.');
        }

        await document.set({
          'syncId': task.syncId,
          'userId': task.userId,
          'name': task.name,
          'description': task.description,
          'createdAt': Timestamp.fromDate(task.createdAt),
          'updatedAt': Timestamp.fromDate(task.updatedAt),
          'archived': task.archived,
          'deletedAt': Timestamp.fromDate(deletedAt),
        });

        await _taskRepository.markTaskAsSynced(task.id);

      case 'synced':
        break;

      default:
        throw StateError('Unknown task sync status: ${task.syncStatus}');
    }
  }

  Future<void> _pullRemoteTasks(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .get();

    for (final document in snapshot.docs) {
      final data = document.data();

      final syncId = data['syncId'] as String?;
      final remoteUserId = data['userId'] as String?;
      final name = data['name'] as String?;
      final description = data['description'] as String?;

      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

      final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();

      final archived = data['archived'] as bool? ?? false;

      final deletedAt = (data['deletedAt'] as Timestamp?)?.toDate();

      if (syncId == null ||
          remoteUserId == null ||
          name == null ||
          createdAt == null ||
          updatedAt == null) {
        continue;
      }

      // Defense in depth.
      if (remoteUserId != userId) {
        continue;
      }

      final localTask = await _taskRepository.getTaskBySyncId(syncId);

      // Task exists remotely but not locally.
      if (localTask == null) {
        await _taskRepository.insertRemoteTask(
          syncId: syncId,
          userId: userId,
          name: name,
          description: description,
          createdAt: createdAt,
          updatedAt: updatedAt,
          archived: archived,
          deletedAt: deletedAt,
        );

        continue;
      }

      // Never overwrite a local change that hasn't
      // successfully synchronized yet.
      if (!updatedAt.isAfter(localTask.updatedAt)) {
        continue;
      }

      if (localTask.syncStatus != SyncStatus.synced.name) {
        continue;
      }

      await _taskRepository.updateFromRemote(
        id: localTask.id,
        name: name,
        description: description,
        createdAt: createdAt,
        updatedAt: updatedAt,
        archived: archived,
        deletedAt: deletedAt,
      );
    }
  }
}
