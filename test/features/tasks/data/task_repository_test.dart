import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:time_tracker/core/services/database/app_database.dart';
import 'package:time_tracker/core/sync/sync_status.dart';
import 'package:time_tracker/features/tasks/data/task_repository.dart';

void main() {
  late AppDatabase database;
  late TaskRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());

    repository = TaskRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('TaskRepository', () {
    test('createTask stores a task', () async {
      final id = await repository.createTask(
        name: 'Build feature',
        description: 'Implement the new feature',
        syncId: 'task-1',
        userId: 'user-1',
      );

      final task = await repository.getTaskById(id);

      expect(task, isNotNull);
      expect(task!.id, id);
      expect(task.syncId, 'task-1');
      expect(task.userId, 'user-1');
      expect(task.name, 'Build feature');
      expect(task.description, 'Implement the new feature');
      expect(task.archived, isFalse);
      expect(task.favorite, isFalse);
      expect(task.deletedAt, isNull);
      expect(task.syncStatus, SyncStatus.pendingCreate.name);
    });

    test('createTask supports a null description', () async {
      final id = await repository.createTask(
        name: 'Simple task',
        syncId: 'task-1',
        userId: 'user-1',
      );

      final task = await repository.getTaskById(id);

      expect(task, isNotNull);
      expect(task!.description, isNull);
    });

    test('getTasks returns only active tasks for the user', () async {
      await repository.createTask(
        name: 'User 1 Task',
        syncId: 'task-1',
        userId: 'user-1',
      );

      await repository.createTask(
        name: 'User 2 Task',
        syncId: 'task-2',
        userId: 'user-2',
      );

      await repository.createTask(
        name: 'Another User 1 Task',
        syncId: 'task-3',
        userId: 'user-1',
      );

      final tasks = await repository.getTasks('user-1');

      expect(tasks, hasLength(2));
      expect(tasks.every((task) => task.userId == 'user-1'), isTrue);
    });

    test('getTasks excludes archived tasks', () async {
      final id = await repository.createTask(
        name: 'Archived Task',
        syncId: 'task-1',
        userId: 'user-1',
      );

      await repository.archiveTask(id);

      final tasks = await repository.getTasks('user-1');

      expect(tasks, isEmpty);
    });

    test('getTasks excludes deleted tasks', () async {
      final id = await repository.createTask(
        name: 'Deleted Task',
        syncId: 'task-1',
        userId: 'user-1',
      );

      await repository.deleteTask(id);

      final tasks = await repository.getTasks('user-1');

      expect(tasks, isEmpty);
    });

    test('archiveTask archives the task', () async {
      final id = await repository.createTask(
        name: 'Task',
        syncId: 'task-1',
        userId: 'user-1',
      );

      await repository.archiveTask(id);

      final task = await repository.getTaskById(id);

      expect(task, isNotNull);
      expect(task!.archived, isTrue);
      expect(task.syncStatus, SyncStatus.pendingUpdate.name);
      expect(task.updatedAt, isNotNull);
    });

    test('restoreTask restores an archived task', () async {
      final id = await repository.createTask(
        name: 'Task',
        syncId: 'task-1',
        userId: 'user-1',
      );

      await repository.archiveTask(id);
      await repository.restoreTask(id);

      final task = await repository.getTaskById(id);

      expect(task, isNotNull);
      expect(task!.archived, isFalse);
      expect(task.syncStatus, SyncStatus.pendingUpdate.name);
    });

    test('getArchivedTasks returns archived tasks', () async {
      final activeId = await repository.createTask(
        name: 'Active Task',
        syncId: 'task-1',
        userId: 'user-1',
      );

      final archivedId = await repository.createTask(
        name: 'Archived Task',
        syncId: 'task-2',
        userId: 'user-1',
      );

      await repository.archiveTask(archivedId);

      final archived = await repository.getArchivedTasks('user-1');

      expect(archived, hasLength(1));
      expect(archived.first.id, archivedId);
      expect(archived.first.name, 'Archived Task');
      expect(archived.first.archived, isTrue);

      final active = await repository.getTasks('user-1');

      expect(active, hasLength(1));
      expect(active.first.id, activeId);
    });

    test('getArchivedTasks excludes deleted tasks', () async {
      final id = await repository.createTask(
        name: 'Archived Task',
        syncId: 'task-1',
        userId: 'user-1',
      );

      await repository.archiveTask(id);
      await repository.deleteTask(id);

      final archived = await repository.getArchivedTasks('user-1');

      expect(archived, isEmpty);
    });

    test('updateTask updates name and description', () async {
      final id = await repository.createTask(
        name: 'Old Name',
        description: 'Old description',
        syncId: 'task-1',
        userId: 'user-1',
      );

      await repository.updateTask(
        id: id,
        name: 'New Name',
        description: 'New description',
      );

      final task = await repository.getTaskById(id);

      expect(task, isNotNull);
      expect(task!.name, 'New Name');
      expect(task.description, 'New description');
      expect(task.syncStatus, SyncStatus.pendingUpdate.name);
    });

    test('updateTask can clear the description', () async {
      final id = await repository.createTask(
        name: 'Task',
        description: 'Description',
        syncId: 'task-1',
        userId: 'user-1',
      );

      await repository.updateTask(id: id, name: 'Task', description: null);

      final task = await repository.getTaskById(id);

      expect(task, isNotNull);
      expect(task!.description, isNull);
    });

    test('toggleFavorite changes favorite from false to true', () async {
      final id = await repository.createTask(
        name: 'Task',
        syncId: 'task-1',
        userId: 'user-1',
      );

      final before = await repository.getTaskById(id);

      expect(before, isNotNull);
      expect(before!.favorite, isFalse);

      await repository.toggleFavorite(id);

      final after = await repository.getTaskById(id);

      expect(after, isNotNull);
      expect(after!.favorite, isTrue);
      expect(after.syncStatus, SyncStatus.pendingUpdate.name);
    });

    test('toggleFavorite changes favorite from true to false', () async {
      final id = await repository.createTask(
        name: 'Task',
        syncId: 'task-1',
        userId: 'user-1',
      );

      await repository.toggleFavorite(id);
      await repository.toggleFavorite(id);

      final task = await repository.getTaskById(id);

      expect(task, isNotNull);
      expect(task!.favorite, isFalse);
    });

    test('toggleFavorite throws when task does not exist', () async {
      expect(
        () => repository.toggleFavorite(999999),
        throwsA(isA<StateError>()),
      );
    });

    test('getTaskById returns the requested task', () async {
      final id = await repository.createTask(
        name: 'Find Me',
        syncId: 'task-1',
        userId: 'user-1',
      );

      final task = await repository.getTaskById(id);

      expect(task, isNotNull);
      expect(task!.id, id);
      expect(task.name, 'Find Me');
    });

    test('getTaskById returns null for unknown id', () async {
      final task = await repository.getTaskById(999999);

      expect(task, isNull);
    });

    test('getTaskBySyncId returns the matching task', () async {
      await repository.createTask(
        name: 'Find By Sync ID',
        syncId: 'unique-sync-id',
        userId: 'user-1',
      );

      final task = await repository.getTaskBySyncId('unique-sync-id');

      expect(task, isNotNull);
      expect(task!.syncId, 'unique-sync-id');
      expect(task.name, 'Find By Sync ID');
    });

    test('getTaskBySyncId returns null for unknown sync id', () async {
      final task = await repository.getTaskBySyncId('does-not-exist');

      expect(task, isNull);
    });

    test('getPendingSyncTasks returns unsynced tasks', () async {
      await repository.createTask(
        name: 'Pending Task',
        syncId: 'task-1',
        userId: 'user-1',
      );

      final pending = await repository.getPendingSyncTasks('user-1');

      expect(pending, hasLength(1));
      expect(pending.first.syncId, 'task-1');
      expect(pending.first.syncStatus, SyncStatus.pendingCreate.name);
    });

    test('getPendingSyncTasks excludes synced tasks', () async {
      final id = await repository.createTask(
        name: 'Synced Task',
        syncId: 'task-1',
        userId: 'user-1',
      );

      await repository.markTaskAsSynced(id);

      final pending = await repository.getPendingSyncTasks('user-1');

      expect(pending, isEmpty);
    });

    test('getPendingSyncTasks returns pending updates', () async {
      final id = await repository.createTask(
        name: 'Task',
        syncId: 'task-1',
        userId: 'user-1',
      );

      await repository.markTaskAsSynced(id);

      await repository.updateTask(id: id, name: 'Updated Task');

      final pending = await repository.getPendingSyncTasks('user-1');

      expect(pending, hasLength(1));
      expect(pending.first.id, id);
      expect(pending.first.syncStatus, SyncStatus.pendingUpdate.name);
    });

    test('getPendingSyncTasks returns pending deletes', () async {
      final id = await repository.createTask(
        name: 'Task',
        syncId: 'task-1',
        userId: 'user-1',
      );

      await repository.markTaskAsSynced(id);
      await repository.deleteTask(id);

      final pending = await repository.getPendingSyncTasks('user-1');

      expect(pending, hasLength(1));
      expect(pending.first.id, id);
      expect(pending.first.syncStatus, SyncStatus.pendingDelete.name);
    });

    test('getPendingSyncTasks isolates users', () async {
      await repository.createTask(
        name: 'User 1 Task',
        syncId: 'user-1-task',
        userId: 'user-1',
      );

      await repository.createTask(
        name: 'User 2 Task',
        syncId: 'user-2-task',
        userId: 'user-2',
      );

      final user1Pending = await repository.getPendingSyncTasks('user-1');

      final user2Pending = await repository.getPendingSyncTasks('user-2');

      expect(user1Pending, hasLength(1));
      expect(user1Pending.first.userId, 'user-1');

      expect(user2Pending, hasLength(1));
      expect(user2Pending.first.userId, 'user-2');
    });

    test('markTaskAsSynced changes sync status to synced', () async {
      final id = await repository.createTask(
        name: 'Task',
        syncId: 'task-1',
        userId: 'user-1',
      );

      await repository.markTaskAsSynced(id);

      final task = await repository.getTaskById(id);

      expect(task, isNotNull);
      expect(task!.syncStatus, SyncStatus.synced.name);
    });

    test('deleteTask soft deletes the task', () async {
      final id = await repository.createTask(
        name: 'Delete Me',
        syncId: 'task-1',
        userId: 'user-1',
      );

      await repository.deleteTask(id);

      final task = await repository.getTaskById(id);

      expect(task, isNotNull);
      expect(task!.deletedAt, isNotNull);
      expect(task.syncStatus, SyncStatus.pendingDelete.name);
    });

    test('deleteTask does not physically remove the task', () async {
      final id = await repository.createTask(
        name: 'Delete Me',
        syncId: 'task-1',
        userId: 'user-1',
      );

      await repository.deleteTask(id);

      final task = await repository.getTaskById(id);

      expect(task, isNotNull);
      expect(task!.id, id);
      expect(task.name, 'Delete Me');
    });

    test('insertRemoteTask stores a synced task', () async {
      final createdAt = DateTime(2026, 1, 1, 10, 0, 0);
      final updatedAt = DateTime(2026, 1, 1, 11, 0, 0);

      await repository.insertRemoteTask(
        syncId: 'remote-task-1',
        userId: 'user-1',
        name: 'Remote Task',
        description: 'Downloaded from Firebase',
        createdAt: createdAt,
        updatedAt: updatedAt,
        archived: false,
        favorite: true,
        deletedAt: null,
      );

      final task = await repository.getTaskBySyncId('remote-task-1');

      expect(task, isNotNull);
      expect(task!.syncId, 'remote-task-1');
      expect(task.userId, 'user-1');
      expect(task.name, 'Remote Task');
      expect(task.description, 'Downloaded from Firebase');
      expect(task.createdAt, createdAt);
      expect(task.updatedAt, updatedAt);
      expect(task.archived, isFalse);
      expect(task.favorite, isTrue);
      expect(task.deletedAt, isNull);
      expect(task.syncStatus, SyncStatus.synced.name);
    });

    test('insertRemoteTask supports an archived task', () async {
      await repository.insertRemoteTask(
        syncId: 'remote-task-1',
        userId: 'user-1',
        name: 'Archived Remote Task',
        createdAt: DateTime(2026, 1, 1, 10, 0, 0),
        updatedAt: DateTime(2026, 1, 1, 11, 0, 0),
        archived: true,
        favorite: false,
        deletedAt: null,
      );

      final task = await repository.getTaskBySyncId('remote-task-1');

      expect(task, isNotNull);
      expect(task!.archived, isTrue);

      final active = await repository.getTasks('user-1');
      final archived = await repository.getArchivedTasks('user-1');

      expect(active, isEmpty);
      expect(archived, hasLength(1));
    });

    test('insertRemoteTask supports a deleted task', () async {
      final deletedAt = DateTime(2026, 1, 2, 10, 0, 0);

      await repository.insertRemoteTask(
        syncId: 'remote-task-1',
        userId: 'user-1',
        name: 'Deleted Remote Task',
        createdAt: DateTime(2026, 1, 1, 10, 0, 0),
        updatedAt: DateTime(2026, 1, 2, 10, 0, 0),
        archived: false,
        favorite: false,
        deletedAt: deletedAt,
      );

      final task = await repository.getTaskBySyncId('remote-task-1');

      expect(task, isNotNull);
      expect(task!.deletedAt, deletedAt);

      final active = await repository.getTasks('user-1');

      expect(active, isEmpty);
    });

    test('updateFromRemote updates all task fields', () async {
      final id = await repository.createTask(
        name: 'Old Name',
        description: 'Old description',
        syncId: 'task-1',
        userId: 'user-1',
      );

      final createdAt = DateTime(2026, 1, 1, 10, 0, 0);
      final updatedAt = DateTime(2026, 1, 2, 10, 0, 0);

      await repository.updateFromRemote(
        id: id,
        name: 'Remote Name',
        description: 'Remote description',
        createdAt: createdAt,
        updatedAt: updatedAt,
        archived: true,
        favorite: true,
        deletedAt: null,
      );

      final task = await repository.getTaskById(id);

      expect(task, isNotNull);
      expect(task!.name, 'Remote Name');
      expect(task.description, 'Remote description');
      expect(task.createdAt, createdAt);
      expect(task.updatedAt, updatedAt);
      expect(task.archived, isTrue);
      expect(task.favorite, isTrue);
      expect(task.deletedAt, isNull);
      expect(task.syncStatus, SyncStatus.synced.name);
    });

    test('updateFromRemote can set deletedAt', () async {
      final id = await repository.createTask(
        name: 'Task',
        syncId: 'task-1',
        userId: 'user-1',
      );

      final deletedAt = DateTime(2026, 1, 2, 10, 0, 0);

      await repository.updateFromRemote(
        id: id,
        name: 'Task',
        description: null,
        createdAt: DateTime(2026, 1, 1, 10, 0, 0),
        updatedAt: DateTime(2026, 1, 2, 10, 0, 0),
        archived: false,
        favorite: false,
        deletedAt: deletedAt,
      );

      final task = await repository.getTaskById(id);

      expect(task, isNotNull);
      expect(task!.deletedAt, deletedAt);
      expect(task.syncStatus, SyncStatus.synced.name);
    });

    test('updateFromRemote can clear deletedAt', () async {
      final id = await repository.createTask(
        name: 'Task',
        syncId: 'task-1',
        userId: 'user-1',
      );

      final deletedAt = DateTime(2026, 1, 2, 10, 0, 0);

      await repository.updateFromRemote(
        id: id,
        name: 'Task',
        description: null,
        createdAt: DateTime(2026, 1, 1, 10, 0, 0),
        updatedAt: DateTime(2026, 1, 2, 10, 0, 0),
        archived: false,
        favorite: false,
        deletedAt: deletedAt,
      );

      await repository.updateFromRemote(
        id: id,
        name: 'Restored Task',
        description: null,
        createdAt: DateTime(2026, 1, 1, 10, 0, 0),
        updatedAt: DateTime(2026, 1, 3, 10, 0, 0),
        archived: false,
        favorite: false,
        deletedAt: null,
      );

      final task = await repository.getTaskById(id);

      expect(task, isNotNull);
      expect(task!.deletedAt, isNull);
      expect(task.name, 'Restored Task');
      expect(task.syncStatus, SyncStatus.synced.name);
    });

    test('favorite state survives archive and restore', () async {
      final id = await repository.createTask(
        name: 'Favorite Task',
        syncId: 'task-1',
        userId: 'user-1',
      );

      await repository.toggleFavorite(id);
      await repository.archiveTask(id);
      await repository.restoreTask(id);

      final task = await repository.getTaskById(id);

      expect(task, isNotNull);
      expect(task!.favorite, isTrue);
      expect(task.archived, isFalse);
    });

    test('favorite state survives updateTask', () async {
      final id = await repository.createTask(
        name: 'Task',
        syncId: 'task-1',
        userId: 'user-1',
      );

      await repository.toggleFavorite(id);

      await repository.updateTask(
        id: id,
        name: 'Updated Task',
        description: 'Updated description',
      );

      final task = await repository.getTaskById(id);

      expect(task, isNotNull);
      expect(task!.favorite, isTrue);
      expect(task.name, 'Updated Task');
      expect(task.description, 'Updated description');
    });

    test('getTasks orders tasks by createdAt descending', () async {
      final olderId = await repository.createTask(
        name: 'Older Task',
        syncId: 'task-old',
        userId: 'user-1',
      );

      final newerId = await repository.createTask(
        name: 'Newer Task',
        syncId: 'task-new',
        userId: 'user-1',
      );

      final olderCreatedAt = DateTime(2026, 1, 1, 10, 0, 0);
      final newerCreatedAt = DateTime(2026, 1, 2, 10, 0, 0);

      await repository.updateFromRemote(
        id: olderId,
        name: 'Older Task',
        description: null,
        createdAt: olderCreatedAt,
        updatedAt: olderCreatedAt,
        archived: false,
        favorite: false,
        deletedAt: null,
      );

      await repository.updateFromRemote(
        id: newerId,
        name: 'Newer Task',
        description: null,
        createdAt: newerCreatedAt,
        updatedAt: newerCreatedAt,
        archived: false,
        favorite: false,
        deletedAt: null,
      );

      final tasks = await repository.getTasks('user-1');

      expect(tasks, hasLength(2));
      expect(tasks.first.id, newerId);
      expect(tasks.last.id, olderId);
    });

    test('getArchivedTasks orders tasks by updatedAt descending', () async {
      final olderId = await repository.createTask(
        name: 'Older Archived Task',
        syncId: 'task-old',
        userId: 'user-1',
      );

      final newerId = await repository.createTask(
        name: 'Newer Archived Task',
        syncId: 'task-new',
        userId: 'user-1',
      );

      final olderDate = DateTime(2026, 1, 1, 10, 0, 0);
      final newerDate = DateTime(2026, 1, 2, 10, 0, 0);

      await repository.updateFromRemote(
        id: olderId,
        name: 'Older Archived Task',
        description: null,
        createdAt: olderDate,
        updatedAt: olderDate,
        archived: true,
        favorite: false,
        deletedAt: null,
      );

      await repository.updateFromRemote(
        id: newerId,
        name: 'Newer Archived Task',
        description: null,
        createdAt: newerDate,
        updatedAt: newerDate,
        archived: true,
        favorite: false,
        deletedAt: null,
      );

      final tasks = await repository.getArchivedTasks('user-1');

      expect(tasks, hasLength(2));
      expect(tasks.first.id, newerId);
      expect(tasks.last.id, olderId);
    });
  });
  test('getAllTasksForUser returns active, archived, and deleted tasks '
      'for the requested user only', () async {
    final now = DateTime.now();

    await database
        .into(database.tasks)
        .insert(
          TasksCompanion.insert(
            syncId: 'active-task',
            userId: 'user-1',
            name: 'Active task',
            createdAt: now,
            updatedAt: now,
            syncStatus: SyncStatus.synced.name,
          ),
        );

    await database
        .into(database.tasks)
        .insert(
          TasksCompanion.insert(
            syncId: 'archived-task',
            userId: 'user-1',
            name: 'Archived task',
            createdAt: now,
            updatedAt: now,
            archived: const Value(true),
            syncStatus: SyncStatus.synced.name,
          ),
        );

    await database
        .into(database.tasks)
        .insert(
          TasksCompanion.insert(
            syncId: 'deleted-task',
            userId: 'user-1',
            name: 'Deleted task',
            createdAt: now,
            updatedAt: now,
            deletedAt: Value(now),
            syncStatus: SyncStatus.synced.name,
          ),
        );

    await database
        .into(database.tasks)
        .insert(
          TasksCompanion.insert(
            syncId: 'other-user-task',
            userId: 'user-2',
            name: 'Other user task',
            createdAt: now,
            updatedAt: now,
            syncStatus: SyncStatus.synced.name,
          ),
        );

    final tasks = await repository.getAllTasksForUser('user-1');

    expect(tasks, hasLength(3));

    expect(
      tasks.map((task) => task.name),
      containsAll(['Active task', 'Archived task', 'Deleted task']),
    );

    expect(tasks.any((task) => task.name == 'Other user task'), isFalse);

    expect(tasks.every((task) => task.userId == 'user-1'), isTrue);
  });
}
