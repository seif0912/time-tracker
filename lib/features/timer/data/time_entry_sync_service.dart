import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/database/app_database.dart';
// import '../../../core/sync/sync_status.dart';
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
    final pendingEntries = await _timeEntryRepository.getPendingSyncEntries(
      userId,
    );

    for (final entry in pendingEntries) {
      await _syncTimeEntry(entry);
    }
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
      'taskId': entry.taskId,
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
}
