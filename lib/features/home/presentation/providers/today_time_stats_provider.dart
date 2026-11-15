import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/data/current_user_id_provider.dart';
import '../../../timer/data/time_entry_providers.dart';
import '../../../timer/presentation/timer_controller.dart';
import '../../domain/today_time_stats.dart';

final todayTimeStatsProvider = FutureProvider<TodayTimeStats>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final timerState = ref.watch(timerControllerProvider);

  if (userId == null) {
    return const TodayTimeStats(
      totalSeconds: 0,
      hourlySeconds: [
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
      ],
    );
  }

  final now = DateTime.now();
  final dayStart = DateTime(now.year, now.month, now.day);

  final runningSegmentStartedAt =
      timerState.runningSession?.currentSegmentStartedAt;

  return ref
      .read(timeEntryRepositoryProvider)
      .getTodayStats(
        userId: userId,
        now: now,
        dayStart: dayStart,
        runningSegmentStartedAt: runningSegmentStartedAt,
      );
});
