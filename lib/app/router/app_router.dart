// import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/tasks/presentation/tasks_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/tasks',

  routes: [
    GoRoute(
      path: '/tasks',
      builder: (context, state) {
        return const TasksScreen();
      },
    ),
  ],
);
