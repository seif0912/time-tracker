import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:time_tracker/core/services/database/app_database.dart';
import 'package:time_tracker/features/timer/data/time_entry_repository.dart';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:time_tracker/core/sync/sync_status.dart';

void main() {
  late AppDatabase database;
  late TimeEntryRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());

    repository = TimeEntryRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('TimeEntryRepository', () {
    test('createTimeEntry stores a completed entry', () async {
      final startedAt = DateTime(2026, 1, 1, 10, 0, 0);
      final endedAt = DateTime(2026, 1, 1, 10, 2, 0);

      final entry = await repository.createTimeEntry(
        taskId: 1,
        syncId: 'entry-1',
        userId: 'user-1',
        startedAt: startedAt,
        endedAt: endedAt,
        durationSeconds: 120,
      );

      expect(entry.id, greaterThan(0));
      expect(entry.taskId, 1);
      expect(entry.syncId, 'entry-1');
      expect(entry.userId, 'user-1');
      expect(entry.startedAt, startedAt);
      expect(entry.endedAt, endedAt);
      expect(entry.durationSeconds, 120);
      expect(entry.deletedAt, isNull);
    });

    test(
      'getEntriesForUser returns only active entries for the user',
      () async {
        final baseTime = DateTime(2026, 1, 1, 10, 0, 0);

        await repository.createTimeEntry(
          taskId: 1,
          syncId: 'entry-1',
          userId: 'user-1',
          startedAt: baseTime,
          endedAt: baseTime.add(const Duration(minutes: 2)),
          durationSeconds: 120,
        );

        await repository.createTimeEntry(
          taskId: 2,
          syncId: 'entry-2',
          userId: 'user-1',
          startedAt: baseTime.add(const Duration(hours: 1)),
          endedAt: baseTime.add(const Duration(hours: 1, minutes: 3)),
          durationSeconds: 180,
        );

        await repository.createTimeEntry(
          taskId: 3,
          syncId: 'entry-3',
          userId: 'user-2',
          startedAt: baseTime.add(const Duration(hours: 2)),
          endedAt: baseTime.add(const Duration(hours: 2, minutes: 5)),
          durationSeconds: 300,
        );

        final entries = await repository.getEntriesForUser('user-1');

        expect(entries, hasLength(2));
        expect(entries.every((entry) => entry.userId == 'user-1'), isTrue);
      },
    );

    test('getEntriesForUser excludes deleted entries', () async {
      final now = DateTime(2026, 1, 1, 10, 0, 0);

      await repository.createTimeEntry(
        taskId: 1,
        syncId: 'entry-active',
        userId: 'user-1',
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 2)),
        durationSeconds: 120,
      );

      await repository.createTimeEntry(
        taskId: 2,
        syncId: 'entry-deleted',
        userId: 'user-1',
        startedAt: now.add(const Duration(hours: 1)),
        endedAt: now.add(const Duration(hours: 1, minutes: 2)),
        durationSeconds: 120,
      );

      final deletedEntry = await repository.getTimeEntryBySyncId(
        'entry-deleted',
      );

      expect(deletedEntry, isNotNull);

      await repository.updateFromRemote(
        id: deletedEntry!.id,
        taskId: deletedEntry.taskId,
        startedAt: deletedEntry.startedAt,
        endedAt: deletedEntry.endedAt,
        durationSeconds: deletedEntry.durationSeconds,
        createdAt: deletedEntry.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: DateTime.now(),
      );

      final entries = await repository.getEntriesForUser('user-1');

      expect(entries, hasLength(1));
      expect(entries.first.syncId, 'entry-active');
    });

    test('getEntriesForTask returns entries for the requested task', () async {
      final baseTime = DateTime(2026, 1, 1, 10, 0, 0);

      await repository.createTimeEntry(
        taskId: 1,
        syncId: 'entry-1',
        userId: 'user-1',
        startedAt: baseTime,
        endedAt: baseTime.add(const Duration(minutes: 2)),
        durationSeconds: 120,
      );

      await repository.createTimeEntry(
        taskId: 1,
        syncId: 'entry-2',
        userId: 'user-1',
        startedAt: baseTime.add(const Duration(hours: 1)),
        endedAt: baseTime.add(const Duration(hours: 1, minutes: 3)),
        durationSeconds: 180,
      );

      await repository.createTimeEntry(
        taskId: 2,
        syncId: 'entry-3',
        userId: 'user-1',
        startedAt: baseTime.add(const Duration(hours: 2)),
        endedAt: baseTime.add(const Duration(hours: 2, minutes: 5)),
        durationSeconds: 300,
      );

      final entries = await repository.getEntriesForTask(
        userId: 'user-1',
        taskId: 1,
      );

      expect(entries, hasLength(2));
      expect(entries.every((entry) => entry.taskId == 1), isTrue);
    });

    test('getTotalDurationForTask sums durations', () async {
      final baseTime = DateTime(2026, 1, 1, 10, 0, 0);

      await repository.createTimeEntry(
        taskId: 1,
        syncId: 'entry-1',
        userId: 'user-1',
        startedAt: baseTime,
        endedAt: baseTime.add(const Duration(minutes: 2)),
        durationSeconds: 120,
      );

      await repository.createTimeEntry(
        taskId: 1,
        syncId: 'entry-2',
        userId: 'user-1',
        startedAt: baseTime.add(const Duration(hours: 1)),
        endedAt: baseTime.add(const Duration(hours: 1, minutes: 5)),
        durationSeconds: 300,
      );

      await repository.createTimeEntry(
        taskId: 1,
        syncId: 'entry-3',
        userId: 'user-1',
        startedAt: baseTime.add(const Duration(hours: 2)),
        endedAt: baseTime.add(const Duration(hours: 2, minutes: 1)),
        durationSeconds: 60,
      );

      final total = await repository.getTotalDurationForTask(
        userId: 'user-1',
        taskId: 1,
      );

      expect(total, 480);
    });

    test('getTotalDurationForTask ignores entries from other tasks', () async {
      final baseTime = DateTime(2026, 1, 1, 10, 0, 0);

      await repository.createTimeEntry(
        taskId: 1,
        syncId: 'entry-1',
        userId: 'user-1',
        startedAt: baseTime,
        endedAt: baseTime.add(const Duration(minutes: 2)),
        durationSeconds: 120,
      );

      await repository.createTimeEntry(
        taskId: 2,
        syncId: 'entry-2',
        userId: 'user-1',
        startedAt: baseTime.add(const Duration(hours: 1)),
        endedAt: baseTime.add(const Duration(hours: 1, minutes: 10)),
        durationSeconds: 600,
      );

      final total = await repository.getTotalDurationForTask(
        userId: 'user-1',
        taskId: 1,
      );

      expect(total, 120);
    });

    test('getEntriesBetween filters by date range', () async {
      final day1 = DateTime(2026, 1, 1, 10, 0, 0);
      final day2 = DateTime(2026, 1, 2, 10, 0, 0);
      final day3 = DateTime(2026, 1, 3, 10, 0, 0);

      await repository.createTimeEntry(
        taskId: 1,
        syncId: 'entry-day-1',
        userId: 'user-1',
        startedAt: day1,
        endedAt: day1.add(const Duration(minutes: 5)),
        durationSeconds: 300,
      );

      await repository.createTimeEntry(
        taskId: 1,
        syncId: 'entry-day-2',
        userId: 'user-1',
        startedAt: day2,
        endedAt: day2.add(const Duration(minutes: 10)),
        durationSeconds: 600,
      );

      await repository.createTimeEntry(
        taskId: 1,
        syncId: 'entry-day-3',
        userId: 'user-1',
        startedAt: day3,
        endedAt: day3.add(const Duration(minutes: 15)),
        durationSeconds: 900,
      );

      final entries = await repository.getEntriesBetween(
        userId: 'user-1',
        start: day2,
        end: day3,
      );

      expect(entries, hasLength(1));
      expect(entries.first.syncId, 'entry-day-2');
    });

    test('getEntriesBetween excludes entries from other users', () async {
      final start = DateTime(2026, 1, 1, 0, 0, 0);
      final end = DateTime(2026, 1, 2, 0, 0, 0);

      await repository.createTimeEntry(
        taskId: 1,
        syncId: 'entry-user-1',
        userId: 'user-1',
        startedAt: DateTime(2026, 1, 1, 10, 0, 0),
        endedAt: DateTime(2026, 1, 1, 10, 5, 0),
        durationSeconds: 300,
      );

      await repository.createTimeEntry(
        taskId: 1,
        syncId: 'entry-user-2',
        userId: 'user-2',
        startedAt: DateTime(2026, 1, 1, 11, 0, 0),
        endedAt: DateTime(2026, 1, 1, 11, 5, 0),
        durationSeconds: 300,
      );

      final entries = await repository.getEntriesBetween(
        userId: 'user-1',
        start: start,
        end: end,
      );

      expect(entries, hasLength(1));
      expect(entries.first.userId, 'user-1');
    });

    test(
      'getSummaryBetween returns total duration and session count',
      () async {
        final start = DateTime(2026, 1, 1, 0, 0, 0);
        final end = DateTime(2026, 1, 2, 0, 0, 0);

        await repository.createTimeEntry(
          taskId: 1,
          syncId: 'entry-1',
          userId: 'user-1',
          startedAt: DateTime(2026, 1, 1, 10, 0, 0),
          endedAt: DateTime(2026, 1, 1, 10, 5, 0),
          durationSeconds: 300,
        );

        await repository.createTimeEntry(
          taskId: 2,
          syncId: 'entry-2',
          userId: 'user-1',
          startedAt: DateTime(2026, 1, 1, 11, 0, 0),
          endedAt: DateTime(2026, 1, 1, 11, 10, 0),
          durationSeconds: 600,
        );

        final summary = await repository.getSummaryBetween(
          userId: 'user-1',
          start: start,
          end: end,
        );

        expect(summary.totalSeconds, 900);
        expect(summary.sessionCount, 2);
      },
    );

    test('getSummariesForTasks groups entries by task', () async {
      final start = DateTime(2026, 1, 1, 0, 0, 0);
      final end = DateTime(2026, 1, 2, 0, 0, 0);

      await repository.createTimeEntry(
        taskId: 1,
        syncId: 'entry-1',
        userId: 'user-1',
        startedAt: DateTime(2026, 1, 1, 10, 0, 0),
        endedAt: DateTime(2026, 1, 1, 10, 5, 0),
        durationSeconds: 300,
      );

      await repository.createTimeEntry(
        taskId: 1,
        syncId: 'entry-2',
        userId: 'user-1',
        startedAt: DateTime(2026, 1, 1, 11, 0, 0),
        endedAt: DateTime(2026, 1, 1, 11, 10, 0),
        durationSeconds: 600,
      );

      await repository.createTimeEntry(
        taskId: 2,
        syncId: 'entry-3',
        userId: 'user-1',
        startedAt: DateTime(2026, 1, 1, 12, 0, 0),
        endedAt: DateTime(2026, 1, 1, 12, 2, 0),
        durationSeconds: 120,
      );

      final summaries = await repository.getSummariesForTasks(
        userId: 'user-1',
        start: start,
        end: end,
      );

      expect(summaries, hasLength(2));

      expect(summaries[1], isNotNull);
      expect(summaries[1]!.totalSeconds, 900);
      expect(summaries[1]!.sessionCount, 2);

      expect(summaries[2], isNotNull);
      expect(summaries[2]!.totalSeconds, 120);
      expect(summaries[2]!.sessionCount, 1);
    });

    test('getPendingSyncEntries returns unsynced entries', () async {
      final now = DateTime(2026, 1, 1, 10, 0, 0);

      final entry = await repository.createTimeEntry(
        taskId: 1,
        syncId: 'entry-1',
        userId: 'user-1',
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 5)),
        durationSeconds: 300,
      );

      final pending = await repository.getPendingSyncEntries('user-1');

      expect(pending, hasLength(1));
      expect(pending.first.id, entry.id);
    });

    test('markTimeEntryAsSynced removes entry from pending sync', () async {
      final now = DateTime(2026, 1, 1, 10, 0, 0);

      final entry = await repository.createTimeEntry(
        taskId: 1,
        syncId: 'entry-1',
        userId: 'user-1',
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 5)),
        durationSeconds: 300,
      );

      await repository.markTimeEntryAsSynced(entry.id);

      final pending = await repository.getPendingSyncEntries('user-1');

      expect(pending, isEmpty);
    });

    test('getTimeEntryBySyncId returns the matching entry', () async {
      final now = DateTime(2026, 1, 1, 10, 0, 0);

      await repository.createTimeEntry(
        taskId: 1,
        syncId: 'entry-unique',
        userId: 'user-1',
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 5)),
        durationSeconds: 300,
      );

      final entry = await repository.getTimeEntryBySyncId('entry-unique');

      expect(entry, isNotNull);
      expect(entry!.syncId, 'entry-unique');
      expect(entry.taskId, 1);
      expect(entry.userId, 'user-1');
    });

    test('getTimeEntryBySyncId returns null for unknown sync id', () async {
      final entry = await repository.getTimeEntryBySyncId('does-not-exist');

      expect(entry, isNull);
    });
  });
  test('history keeps time entries when their task is deleted', () async {
    final taskId = await database
        .into(database.tasks)
        .insert(
          TasksCompanion.insert(
            syncId: 'task-sync-1',
            userId: 'user-1',
            name: 'Deleted Task',
            description: const Value(null),
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
            syncStatus: SyncStatus.synced.name,
          ),
        );

    await repository.createTimeEntry(
      taskId: taskId,
      syncId: 'entry-sync-1',
      userId: 'user-1',
      startedAt: DateTime(2026, 1, 1, 10),
      endedAt: DateTime(2026, 1, 1, 11),
      durationSeconds: 3600,
    );

    await (database.update(
      database.tasks,
    )..where((task) => task.id.equals(taskId))).write(
      TasksCompanion(
        deletedAt: Value(DateTime(2026, 1, 2)),
        updatedAt: Value(DateTime(2026, 1, 2)),
        syncStatus: Value(SyncStatus.pendingDelete.name),
      ),
    );

    final history = await repository.getHistoryForUser('user-1');

    expect(history, hasLength(1));
    expect(history.first.taskId, taskId);
    expect(history.first.taskName, 'Deleted Task');
    expect(history.first.durationSeconds, 3600);
  });
}
