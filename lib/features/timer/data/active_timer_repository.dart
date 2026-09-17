import 'package:drift/drift.dart';

import '../../../core/services/database/app_database.dart';
import '../domain/timer_state.dart';

class ActiveTimerRepository {
  final AppDatabase database;

  ActiveTimerRepository(this.database);

  Future<List<ActiveTimer>> getForUser(String userId) {
    return (database.select(
      database.activeTimers,
    )..where((timer) => timer.userId.equals(userId))).get();
  }

  Future<ActiveTimer?> getForTask({
    required String userId,
    required int taskId,
  }) {
    return (database.select(database.activeTimers)..where(
          (timer) => timer.userId.equals(userId) & timer.taskId.equals(taskId),
        ))
        .getSingleOrNull();
  }

  Future<void> save({
    required String userId,
    required TimerSessionState session,
  }) async {
    final existing = await getForTask(userId: userId, taskId: session.taskId);

    final companion = ActiveTimersCompanion(
      userId: Value(userId),
      taskId: Value(session.taskId),
      status: Value(session.status.name),
      startedAt: Value(session.startedAt),
      currentSegmentStartedAt: Value(session.currentSegmentStartedAt),
      accumulatedSeconds: Value(session.accumulatedSeconds),
      updatedAt: Value(DateTime.now()),
    );

    if (existing == null) {
      await database.into(database.activeTimers).insert(companion);
    } else {
      await (database.update(
        database.activeTimers,
      )..where((timer) => timer.id.equals(existing.id))).write(companion);
    }
  }

  Future<void> deleteForTask({
    required String userId,
    required int taskId,
  }) async {
    await (database.delete(database.activeTimers)..where(
          (timer) => timer.userId.equals(userId) & timer.taskId.equals(taskId),
        ))
        .go();
  }

  Future<void> deleteForUser(String userId) async {
    await (database.delete(
      database.activeTimers,
    )..where((timer) => timer.userId.equals(userId))).go();
  }

  TimerSessionState toSession(ActiveTimer timer) {
    return TimerSessionState(
      status: TimerStatus.values.byName(timer.status),
      accumulatedSeconds: timer.accumulatedSeconds,
      currentElapsedSeconds: _calculateCurrentElapsed(timer),
      startedAt: timer.startedAt,
      currentSegmentStartedAt: timer.currentSegmentStartedAt,
      taskId: timer.taskId,
    );
  }

  int _calculateCurrentElapsed(ActiveTimer timer) {
    if (timer.status != TimerStatus.running.name ||
        timer.currentSegmentStartedAt == null) {
      return 0;
    }

    return DateTime.now().difference(timer.currentSegmentStartedAt!).inSeconds;
  }
}
