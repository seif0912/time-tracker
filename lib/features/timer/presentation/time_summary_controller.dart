import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_handler.dart';
import '../../../core/logging/app_logger.dart';
import '../../authentication/data/auth_providers.dart';
import '../data/time_entry_providers.dart';
import '../domain/time_summary.dart';
import '../domain/task_time_summary.dart';

final timeSummaryControllerProvider =
    AsyncNotifierProvider<TimeSummaryController, TimeSummary>(
      TimeSummaryController.new,
    );

class TimeSummaryController extends AsyncNotifier<TimeSummary> {
  @override
  Future<TimeSummary> build() {
    ref.watch(authStateChangesProvider);

    return getTodaySummary();
  }

  Future<TimeSummary> getSummaryBetween({
    required DateTime start,
    required DateTime end,
  }) async {
    final user = ref.read(authRepositoryProvider).currentUser;

    if (user == null) {
      return const TimeSummary(totalSeconds: 0, sessionCount: 0);
    }

    try {
      return await ref
          .read(timeEntryRepositoryProvider)
          .getSummaryBetween(userId: user.uid, start: start, end: end);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load time summary',
        error: error,
        stackTrace: stackTrace,
      );

      throw ErrorHandler.handle(error, stackTrace);
    }
  }

  Future<Map<int, TimeSummary>> getTaskSummaries({
    required DateTime start,
    required DateTime end,
  }) async {
    final user = ref.read(authRepositoryProvider).currentUser;

    if (user == null) {
      return {};
    }

    try {
      return await ref
          .read(timeEntryRepositoryProvider)
          .getSummariesForTasks(userId: user.uid, start: start, end: end);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load task time summaries',
        error: error,
        stackTrace: stackTrace,
      );

      throw ErrorHandler.handle(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    try {
      state = AsyncData(await getTodaySummary());
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to refresh time summary',
        error: error,
        stackTrace: stackTrace,
      );

      state = AsyncError(ErrorHandler.handle(error, stackTrace), stackTrace);
    }
  }

  DateTime _startOfDay(DateTime date) {
    final local = date.toLocal();

    return DateTime(local.year, local.month, local.day);
  }

  Future<TimeSummary> getTodaySummary() {
    final today = _startOfDay(DateTime.now());

    return getSummaryBetween(
      start: today,
      end: today.add(const Duration(days: 1)),
    );
  }

  Future<TimeSummary> getThisWeekSummary() async {
    final today = _startOfDay(DateTime.now());

    // Monday = 1, Sunday = 7.
    final start = today.subtract(
      Duration(days: today.weekday - DateTime.monday),
    );

    final end = start.add(const Duration(days: 7));

    return getSummaryBetween(start: start, end: end);
  }

  Future<List<TaskTimeSummary>> getRankedTaskSummaries({
    required DateTime start,
    required DateTime end,
  }) async {
    final summaries = await getTaskSummaries(start: start, end: end);

    final ranked = summaries.entries
        .map(
          (entry) => TaskTimeSummary(
            taskId: entry.key,
            totalSeconds: entry.value.totalSeconds,
            sessionCount: entry.value.sessionCount,
          ),
        )
        .toList();

    ranked.sort((a, b) => b.totalSeconds.compareTo(a.totalSeconds));

    return ranked;
  }
}
