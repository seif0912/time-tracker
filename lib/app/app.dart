import 'package:flutter/material.dart';

import '../core/config/app_environment.dart';
import '../core/theme/app_theme.dart';
import 'router/app_router.dart';

class TimeTrackerApp extends StatelessWidget {
  final AppConfig config;

  const TimeTrackerApp({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: config.appName,

      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,

      routerConfig: appRouter,
    );
  }
}
