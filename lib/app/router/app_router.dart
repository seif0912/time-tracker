import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/data/auth_providers.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/authentication/presentation/signup_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/login',

    redirect: (context, state) {
      if (authState.isLoading) {
        return null;
      }

      final isAuthenticated = authState.hasValue && authState.value != null;

      final isOnAuthPage =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      if (!isAuthenticated && !isOnAuthPage) {
        return '/login';
      }

      if (isAuthenticated && isOnAuthPage) {
        return '/home';
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) {
          return const HomeScreen();
        },
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) {
          return const SignupScreen();
        },
      ),
    ],
  );
});
