import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/authentication/data/auth_providers.dart';
import '../../features/tasks/data/task_sync_providers.dart';
import '../../features/timer/data/time_entry_sync_providers.dart';
import '../logging/app_logger.dart';
import 'connectivity_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/tasks/presentation/task_controller.dart';

final syncControllerProvider = AsyncNotifierProvider<SyncController, void>(
  SyncController.new,
);

class SyncController extends AsyncNotifier<void> with WidgetsBindingObserver {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<User?>? _authSubscription;

  bool _isSyncing = false;

  @override
  Future<void> build() async {
    WidgetsBinding.instance.addObserver(this);

    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _connectivitySubscription?.cancel();
      _authSubscription?.cancel();
    });

    _connectivitySubscription = ref
        .read(connectivityServiceProvider)
        .onConnectivityChanged
        .listen(_handleConnectivityChange);

    _authSubscription = ref
        .read(authRepositoryProvider)
        .authStateChanges
        .listen((user) {
          if (user != null) {
            unawaited(sync());
          }
        });

    await sync();
  }

  Future<void> _handleConnectivityChange(
    List<ConnectivityResult> results,
  ) async {
    final isOnline = results.any((result) => result != ConnectivityResult.none);

    if (!isOnline) {
      return;
    }

    await sync();
  }

  Future<void> sync() async {
    if (_isSyncing) {
      return;
    }

    final user = ref.read(authRepositoryProvider).currentUser;

    if (user == null) {
      return;
    }

    _isSyncing = true;

    try {
      await ref.read(taskSyncServiceProvider).syncTasks(user.uid);

      await ref.read(timeEntrySyncServiceProvider).syncTimeEntries(user.uid);

      ref.invalidate(taskControllerProvider);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Synchronization failed',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _isSyncing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(sync());
    }
  }
}
