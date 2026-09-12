import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_environment.dart';
import '../core/sync/sync_controller.dart';
import '../core/theme/app_theme.dart';
import '../features/profile/presentation/user_profile_controller.dart';
import 'router/app_router.dart';

class TimeTrackerApp extends ConsumerWidget {
  final AppConfig config;

  const TimeTrackerApp({super.key, required this.config});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    ref.watch(userProfileControllerProvider);
    ref.watch(syncControllerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: config.appName,

      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,

      routerConfig: router,
    );
  }
}
