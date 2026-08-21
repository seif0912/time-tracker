import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/time_entry_providers.dart';
import '../domain/timer_state.dart';

final timerControllerProvider = NotifierProvider<TimerController, TimerState>(
  TimerController.new,
);

class TimerController extends Notifier<TimerState> {
  Timer? _ticker;

  @override
  TimerState build() {
    ref.onDispose(() {
      _ticker?.cancel();
    });

    return const TimerState();
  }

  void start({required int taskId}) {
    _ticker?.cancel();

    final now = DateTime.now();

    state = TimerState(
      status: TimerStatus.running,
      startedAt: now,
      currentSegmentStartedAt: now,
      taskId: taskId,
    );

    _startTicker();
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final segmentStart = state.currentSegmentStartedAt;

      if (segmentStart == null) return;

      final elapsed = DateTime.now().difference(segmentStart).inSeconds;

      state = state.copyWith(currentElapsedSeconds: elapsed);
    });
  }

  void pause() {
    if (state.status != TimerStatus.running) return;

    final segmentStart = state.currentSegmentStartedAt;

    if (segmentStart == null) return;

    final segmentDuration = DateTime.now().difference(segmentStart).inSeconds;

    _ticker?.cancel();

    state = state.copyWith(
      status: TimerStatus.paused,
      accumulatedSeconds: state.accumulatedSeconds + segmentDuration,
      currentElapsedSeconds: 0,
      currentSegmentStartedAt: null,
    );
  }

  void resume() {
    if (state.status != TimerStatus.paused) return;

    final now = DateTime.now();

    state = state.copyWith(
      status: TimerStatus.running,
      currentSegmentStartedAt: now,
      currentElapsedSeconds: 0,
    );

    _startTicker();
  }

  Future<void> stop() async {
    if (state.status == TimerStatus.idle) return;

    final currentState = state;

    var totalSeconds = currentState.accumulatedSeconds;

    if (currentState.status == TimerStatus.running &&
        currentState.currentSegmentStartedAt != null) {
      totalSeconds += DateTime.now()
          .difference(currentState.currentSegmentStartedAt!)
          .inSeconds;
    }

    if (totalSeconds <= 0) {
      reset();
      return;
    }

    final taskId = currentState.taskId;
    final startedAt = currentState.startedAt;

    if (taskId == null || startedAt == null) {
      reset();
      return;
    }

    final endedAt = DateTime.now();

    final repository = ref.read(timeEntryRepositoryProvider);

    await repository.createTimeEntry(
      taskId: taskId,
      startedAt: startedAt,
      endedAt: endedAt,
      durationSeconds: totalSeconds,
    );

    reset();
  }

  void reset() {
    _ticker?.cancel();

    state = const TimerState();
  }
}
