import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/core/services/database/app_database.dart';
import 'package:time_tracker/features/timer/data/active_timer_repository.dart';
import 'package:time_tracker/features/timer/domain/timer_state.dart';

void main() {
  // WidgetsFlutterBinding.ensureInitialized();
  late AppDatabase database;
  late ActiveTimerRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ActiveTimerRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('returns no active timers for a new user', () async {
    final timers = await repository.getForUser('user-1');

    expect(timers, isEmpty);
  });

  test('saves and retrieves a running timer', () async {
    final startedAt = DateTime.now().subtract(const Duration(minutes: 5));

    final session = TimerSessionState(
      status: TimerStatus.running,
      startedAt: startedAt,
      currentSegmentStartedAt: startedAt,
      taskId: 1,
    );

    await repository.save(userId: 'user-1', session: session);

    final timers = await repository.getForUser('user-1');

    expect(timers, hasLength(1));
    expect(timers.first.userId, 'user-1');
    expect(timers.first.taskId, 1);
    expect(timers.first.status, TimerStatus.running.name);
    expect(
      timers.first.startedAt,
      DateTime(
        startedAt.year,
        startedAt.month,
        startedAt.day,
        startedAt.hour,
        startedAt.minute,
        startedAt.second,
      ),
    );
  });

  test('updates an existing timer for the same task', () async {
    final startedAt = DateTime.now();

    final firstSession = TimerSessionState(
      status: TimerStatus.running,
      startedAt: startedAt,
      currentSegmentStartedAt: startedAt,
      taskId: 1,
    );

    await repository.save(userId: 'user-1', session: firstSession);

    final secondSession = firstSession.copyWith(
      status: TimerStatus.paused,
      accumulatedSeconds: 120,
      currentSegmentStartedAt: null,
    );

    await repository.save(userId: 'user-1', session: secondSession);

    final timers = await repository.getForUser('user-1');

    expect(timers, hasLength(1));
    expect(timers.first.status, TimerStatus.paused.name);
    expect(timers.first.accumulatedSeconds, 120);
    expect(timers.first.currentSegmentStartedAt, isNull);
  });

  test('supports multiple paused timers for the same user', () async {
    final now = DateTime.now();

    final firstSession = TimerSessionState(
      status: TimerStatus.paused,
      startedAt: now,
      taskId: 1,
      accumulatedSeconds: 60,
    );

    final secondSession = TimerSessionState(
      status: TimerStatus.paused,
      startedAt: now,
      taskId: 2,
      accumulatedSeconds: 120,
    );

    await repository.save(userId: 'user-1', session: firstSession);

    await repository.save(userId: 'user-1', session: secondSession);

    final timers = await repository.getForUser('user-1');

    expect(timers, hasLength(2));
  });

  test('deletes a timer for a specific task', () async {
    final now = DateTime.now();

    await repository.save(
      userId: 'user-1',
      session: TimerSessionState(
        status: TimerStatus.paused,
        startedAt: now,
        taskId: 1,
      ),
    );

    await repository.save(
      userId: 'user-1',
      session: TimerSessionState(
        status: TimerStatus.paused,
        startedAt: now,
        taskId: 2,
      ),
    );

    await repository.deleteForTask(userId: 'user-1', taskId: 1);

    final timers = await repository.getForUser('user-1');

    expect(timers, hasLength(1));
    expect(timers.first.taskId, 2);
  });

  test('converts a running database timer into a session', () {
    final startedAt = DateTime.now().subtract(const Duration(seconds: 10));

    final timer = ActiveTimer(
      id: 1,
      userId: 'user-1',
      taskId: 1,
      status: TimerStatus.running.name,
      startedAt: startedAt,
      currentSegmentStartedAt: startedAt,
      accumulatedSeconds: 30,
      updatedAt: DateTime.now(),
    );

    final session = repository.toSession(timer);

    expect(session.status, TimerStatus.running);
    expect(session.taskId, 1);
    expect(session.accumulatedSeconds, 30);
    expect(session.currentElapsedSeconds, greaterThanOrEqualTo(10));
  });

  test('paused timer has zero current elapsed time', () {
    final timer = ActiveTimer(
      id: 1,
      userId: 'user-1',
      taskId: 1,
      status: TimerStatus.paused.name,
      startedAt: DateTime.now(),
      currentSegmentStartedAt: null,
      accumulatedSeconds: 100,
      updatedAt: DateTime.now(),
    );

    final session = repository.toSession(timer);

    expect(session.status, TimerStatus.paused);
    expect(session.currentElapsedSeconds, 0);
    expect(session.accumulatedSeconds, 100);
    expect(session.totalElapsedSeconds, 100);
  });
}
