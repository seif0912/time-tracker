import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_handler.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/services/database/app_database.dart';
import '../../authentication/data/auth_providers.dart';
import '../data/time_entry_providers.dart';
import '../domain/history_entry.dart';
import '../domain/history_group.dart';

final historyControllerProvider =
    AsyncNotifierProvider<HistoryController, List<HistoryGroup>>(
      HistoryController.new,
    );

class HistoryController extends AsyncNotifier<List<HistoryGroup>> {
  @override
  Future<List<HistoryGroup>> build() async {
    ref.watch(authStateChangesProvider);

    try {
      return await _loadEntries();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load time entries',
        error: error,
        stackTrace: stackTrace,
      );

      throw ErrorHandler.handle(error, stackTrace);
    }
  }

  Future<List<HistoryGroup>> _loadEntries() async {
    final user = ref.read(authRepositoryProvider).currentUser;

    if (user == null) {
      return [];
    }

    final entries = await ref
        .read(timeEntryRepositoryProvider)
        .getHistoryForUser(user.uid);

    return _groupEntriesByDate(entries);
  }

  List<HistoryGroup> _groupEntriesByDate(List<HistoryEntry> entries) {
    final groups = <DateTime, List<HistoryEntry>>{};

    for (final entry in entries) {
      final localDate = entry.startedAt.toLocal();

      final date = DateTime(localDate.year, localDate.month, localDate.day);

      groups.putIfAbsent(date, () => []).add(entry);
    }

    return groups.entries
        .map((group) => HistoryGroup(date: group.key, entries: group.value))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> refresh() async {
    try {
      state = const AsyncLoading();

      state = AsyncData(await _loadEntries());
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to refresh time entries',
        error: error,
        stackTrace: stackTrace,
      );

      state = AsyncError(ErrorHandler.handle(error, stackTrace), stackTrace);
    }
  }

  Future<List<TimeEntry>> getEntriesForTask(int taskId) async {
    final user = ref.read(authRepositoryProvider).currentUser;

    if (user == null) {
      return [];
    }

    try {
      return await ref
          .read(timeEntryRepositoryProvider)
          .getEntriesForTask(userId: user.uid, taskId: taskId);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load time entries for task: $taskId',
        error: error,
        stackTrace: stackTrace,
      );

      throw ErrorHandler.handle(error, stackTrace);
    }
  }
}
