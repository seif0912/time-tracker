import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_handler.dart';
import '../../../core/logging/app_logger.dart';
import '../../authentication/data/auth_providers.dart';
import '../../timer/presentation/time_summary_controller.dart';
import '../domain/dashboard_state.dart';

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardState>(
      DashboardController.new,
    );

class DashboardController extends AsyncNotifier<DashboardState> {
  @override
  Future<DashboardState> build() async {
    ref.watch(authStateChangesProvider);

    return _loadDashboard();
  }

  Future<DashboardState> _loadDashboard() async {
    try {
      final summaryController = ref.read(
        timeSummaryControllerProvider.notifier,
      );

      final today = await summaryController.getTodaySummary();
      final thisWeek = await summaryController.getThisWeekSummary();

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final weekStart = todayStart.subtract(
        Duration(days: todayStart.weekday - DateTime.monday),
      );

      final rankedTasks = await summaryController.getRankedTaskSummaries(
        start: weekStart,
        end: weekStart.add(const Duration(days: 7)),
      );

      return DashboardState(
        today: today,
        thisWeek: thisWeek,
        rankedTasks: rankedTasks,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load dashboard',
        error: error,
        stackTrace: stackTrace,
      );

      throw ErrorHandler.handle(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    try {
      state = AsyncData(await _loadDashboard());
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to refresh dashboard',
        error: error,
        stackTrace: stackTrace,
      );

      state = AsyncError(ErrorHandler.handle(error, stackTrace), stackTrace);
    }
  }
}
