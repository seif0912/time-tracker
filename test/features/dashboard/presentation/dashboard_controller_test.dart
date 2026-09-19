import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:time_tracker/core/services/database/app_database.dart';
import 'package:time_tracker/core/sync/sync_status.dart';
import 'package:time_tracker/features/authentication/data/auth_providers.dart';
import 'package:time_tracker/features/authentication/data/auth_repository.dart';
import 'package:time_tracker/features/dashboard/presentation/dashboard_controller.dart';
import 'package:time_tracker/features/tasks/data/task_providers.dart';
import 'package:time_tracker/features/timer/data/time_entry_providers.dart';
// import 'package:time_tracker/features/timer/domain/task_time_summary.dart';
// import 'package:time_tracker/features/timer/domain/time_summary.dart';
// import 'package:time_tracker/core/services/database/database_provider.dart';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:time_tracker/features/tasks/data/task_repository.dart';
import 'package:time_tracker/features/timer/data/time_entry_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.user);

  final User? user;

  @override
  Stream<User?> get authStateChanges => Stream.value(user);

  @override
  User? get currentUser => user;

  @override
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> signInWithGoogle() {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() {
    throw UnimplementedError();
  }
}

class FakeUser implements User {
  FakeUser(this._uid);

  final String _uid;

  @override
  String get uid => _uid;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError();
  }
}

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('dashboard keeps task names for archived and deleted tasks', () async {
    final user = FakeUser('user-1');

    final timeEntryRepository = TimeEntryRepository(database);

    final now = DateTime.now();

    final archivedTaskId = await database
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

    final deletedTaskId = await database
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

    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - DateTime.monday));

    await timeEntryRepository.createTimeEntry(
      taskId: archivedTaskId,
      syncId: 'entry-archived',
      userId: 'user-1',
      startedAt: weekStart.add(const Duration(hours: 1)),
      endedAt: weekStart.add(const Duration(hours: 2)),
      durationSeconds: 3600,
    );

    await timeEntryRepository.createTimeEntry(
      taskId: deletedTaskId,
      syncId: 'entry-deleted',
      userId: 'user-1',
      startedAt: weekStart.add(const Duration(hours: 3)),
      endedAt: weekStart.add(const Duration(hours: 4)),
      durationSeconds: 3600,
    );

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository(user)),
        taskRepositoryProvider.overrideWithValue(TaskRepository(database)),
        timeEntryRepositoryProvider.overrideWithValue(
          TimeEntryRepository(database),
        ),
      ],
    );

    addTearDown(container.dispose);

    final state = await container.read(dashboardControllerProvider.future);

    expect(state.taskNames[archivedTaskId], 'Archived task');

    expect(state.taskNames[deletedTaskId], 'Deleted task');

    expect(
      state.rankedTasks.map((task) => task.taskId),
      containsAll([archivedTaskId, deletedTaskId]),
    );
  });
}
