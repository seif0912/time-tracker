import 'package:drift/drift.dart';

import '../../../core/services/database/app_database.dart';
import '../../../core/sync/sync_status.dart';

class TaskRepository {
  final AppDatabase database;

  TaskRepository(this.database);

  Future<List<Task>> getTasks(String userId) {
    return (database.select(database.tasks)
          ..where(
            (task) =>
                task.userId.equals(userId) &
                task.archived.equals(false) &
                task.deletedAt.isNull(),
          )
          ..orderBy([
            (task) => OrderingTerm(
              expression: task.createdAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  Future<int> createTask({
    required String name,
    String? description,
    required String syncId,
    required String userId,
  }) {
    final now = DateTime.now();

    return database
        .into(database.tasks)
        .insert(
          TasksCompanion.insert(
            syncId: syncId,
            userId: userId,
            name: name,
            description: Value(description),
            createdAt: now,
            updatedAt: now,
            syncStatus: SyncStatus.pendingCreate.name,
          ),
        );
  }

  Future<void> archiveTask(int id) {
    return (database.update(
      database.tasks,
    )..where((task) => task.id.equals(id))).write(
      TasksCompanion(
        archived: const Value(true),
        updatedAt: Value(DateTime.now()),
        syncStatus: Value(SyncStatus.pendingUpdate.name),
      ),
    );
  }

  /// Returns tasks that have local changes which have not
  /// successfully synchronized with Firebase.
  Future<List<Task>> getPendingSyncTasks(String userId) {
    return (database.select(database.tasks)..where(
          (task) =>
              task.userId.equals(userId) &
              task.syncStatus.isNotValue(SyncStatus.synced.name),
        ))
        .get();
  }

  /// Marks a task as synchronized with Firebase.
  Future<void> markTaskAsSynced(int id) {
    return (database.update(database.tasks)
          ..where((task) => task.id.equals(id)))
        .write(TasksCompanion(syncStatus: Value(SyncStatus.synced.name)));
  }

  Future<Task?> getTaskById(int id) {
    return (database.select(
      database.tasks,
    )..where((task) => task.id.equals(id))).getSingleOrNull();
  }

  Future<Task?> getTaskBySyncId(String syncId) {
    return (database.select(
      database.tasks,
    )..where((task) => task.syncId.equals(syncId))).getSingleOrNull();
  }

  Future<void> insertRemoteTask({
    required String syncId,
    required String userId,
    required String name,
    String? description,
    required DateTime createdAt,
    required DateTime updatedAt,
    required bool archived,
    DateTime? deletedAt,
  }) async {
    await database
        .into(database.tasks)
        .insert(
          TasksCompanion.insert(
            syncId: syncId,
            userId: userId,
            name: name,
            description: Value(description),
            createdAt: createdAt,
            updatedAt: updatedAt,
            archived: Value(archived),
            syncStatus: SyncStatus.synced.name,
            deletedAt: Value(deletedAt),
          ),
        );
  }

  Future<void> updateFromRemote({
    required int id,
    required String name,
    String? description,
    required DateTime createdAt,
    required DateTime updatedAt,
    required bool archived,
    DateTime? deletedAt,
  }) async {
    await (database.update(
      database.tasks,
    )..where((task) => task.id.equals(id))).write(
      TasksCompanion(
        name: Value(name),
        description: Value(description),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
        archived: Value(archived),
        deletedAt: Value(deletedAt),
        syncStatus: Value(SyncStatus.synced.name),
      ),
    );
  }

  Future<void> deleteTask(int id) {
    return (database.update(
      database.tasks,
    )..where((task) => task.id.equals(id))).write(
      TasksCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        syncStatus: Value(SyncStatus.pendingDelete.name),
      ),
    );
  }

  Future<void> updateTask({
    required int id,
    required String name,
    String? description,
  }) {
    return (database.update(
      database.tasks,
    )..where((task) => task.id.equals(id))).write(
      TasksCompanion(
        name: Value(name),
        description: Value(description),
        updatedAt: Value(DateTime.now()),
        syncStatus: Value(SyncStatus.pendingUpdate.name),
      ),
    );
  }
}
