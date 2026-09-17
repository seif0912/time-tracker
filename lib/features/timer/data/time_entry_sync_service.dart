import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/database/app_database.dart';
import '../../tasks/data/task_repository.dart';
import 'time_entry_repository.dart';

class TimeEntrySyncService {
  TimeEntrySyncService({
    required this._timeEntryRepository,
    required this._taskRepository,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final TimeEntryRepository _timeEntryRepository;
  final TaskRepository _taskRepository;
  final FirebaseFirestore _firestore;

  Future<void> syncTimeEntries(String userId) async {
    // Push local changes first.
    final pendingEntries = await _timeEntryRepository.getPendingSyncEntries(
      userId,
    );

    for (final entry in pendingEntries) {
      await _syncTimeEntry(entry);
    }

    // Pull remote changes afterwards.
    await _pullRemoteTimeEntries(userId);
  }

  Future<void> _syncTimeEntry(TimeEntry entry) async {
    final task = await _taskRepository.getTaskById(entry.taskId);

    if (task == null) {
      throw StateError(
        'Cannot sync time entry ${entry.syncId}: '
        'task ${entry.taskId} was not found.',
      );
    }

    final document = _firestore
        .collection('users')
        .doc(entry.userId)
        .collection('timeEntries')
        .doc(entry.syncId);

    final data = <String, dynamic>{
      'syncId': entry.syncId,
      'userId': entry.userId,
      'taskSyncId': task.syncId,
      'startedAt': Timestamp.fromDate(entry.startedAt),
      'endedAt': entry.endedAt == null
          ? null
          : Timestamp.fromDate(entry.endedAt!),
      'durationSeconds': entry.durationSeconds,
      'createdAt': Timestamp.fromDate(entry.createdAt),
      'updatedAt': Timestamp.fromDate(entry.updatedAt),
      'deletedAt': entry.deletedAt == null
          ? null
          : Timestamp.fromDate(entry.deletedAt!),
    };

    switch (entry.syncStatus) {
      case 'pendingCreate':
      case 'pendingUpdate':
        await document.set(data);
        await _timeEntryRepository.markTimeEntryAsSynced(entry.id);

      case 'pendingDelete':
        await document.delete();
        await _timeEntryRepository.markTimeEntryAsSynced(entry.id);

      case 'synced':
        break;

      default:
        throw StateError('Unknown time entry sync status: ${entry.syncStatus}');
    }
  }

  Future<void> _pullRemoteTimeEntries(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('timeEntries')
        .get();

    for (final document in snapshot.docs) {
      final data = document.data();

      final syncId = data['syncId'] as String?;
      final remoteUserId = data['userId'] as String?;
      final taskSyncId = data['taskSyncId'] as String?;

      final startedAt = (data['startedAt'] as Timestamp?)?.toDate();
      final endedAt = (data['endedAt'] as Timestamp?)?.toDate();

      final durationSeconds = data['durationSeconds'] as int?;

      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();

      final deletedAt = (data['deletedAt'] as Timestamp?)?.toDate();

      if (syncId == null ||
          remoteUserId == null ||
          taskSyncId == null ||
          startedAt == null ||
          createdAt == null ||
          updatedAt == null) {
        continue;
      }

      // Defense in depth.
      if (remoteUserId != userId) {
        continue;
      }

      // Resolve the stable remote task ID to the local Drift task ID.
      final localTask = await _taskRepository.getTaskBySyncId(taskSyncId);

      if (localTask == null) {
        // The task has not arrived locally yet.
        // Task sync runs before time-entry sync, so this should normally
        // only happen when the remote data is inconsistent.
        continue;
      }

      final localEntry = await _timeEntryRepository.getTimeEntryBySyncId(
        syncId,
      );

      // Remote entry does not exist locally.
      if (localEntry == null) {
        await _timeEntryRepository.insertRemoteTimeEntry(
          syncId: syncId,
          userId: userId,
          taskId: localTask.id,
          startedAt: startedAt,
          endedAt: endedAt,
          durationSeconds: durationSeconds,
          createdAt: createdAt,
          updatedAt: updatedAt,
          deletedAt: deletedAt,
        );

        continue;
      }

      // Never overwrite a local change that has not synchronized yet.
      if (localEntry.syncStatus != 'synced') {
        continue;
      }

      // Remote version is not newer.
      if (!updatedAt.isAfter(localEntry.updatedAt)) {
        continue;
      }

      await _timeEntryRepository.updateFromRemote(
        id: localEntry.id,
        taskId: localTask.id,
        startedAt: startedAt,
        endedAt: endedAt,
        durationSeconds: durationSeconds,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );
    }
  }
}
