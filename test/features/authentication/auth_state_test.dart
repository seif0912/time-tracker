import 'package:flutter_test/flutter_test.dart';

import 'package:time_tracker/features/authentication/domain/auth_state.dart';

void main() {
  group('AuthState', () {
    test('starts in initial state', () {
      const state = AuthState();

      expect(state.status, AuthStatus.initial);
      expect(state.user, isNull);
      expect(state.errorMessage, isNull);
      expect(state.isInitializing, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.isAuthenticated, isFalse);
    });

    test('isLoading is true when status is loading', () {
      const state = AuthState(status: AuthStatus.loading);

      expect(state.isLoading, isTrue);
      expect(state.isInitializing, isFalse);
    });

    test('isAuthenticated is true when status is authenticated', () {
      const state = AuthState(status: AuthStatus.authenticated);

      expect(state.isAuthenticated, isTrue);
    });

    test('copyWith changes status', () {
      const state = AuthState();

      final updated = state.copyWith(status: AuthStatus.loading);

      expect(updated.status, AuthStatus.loading);
      expect(updated.isLoading, isTrue);
    });

    test('copyWith preserves existing values', () {
      const state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Something went wrong',
      );

      final updated = state.copyWith(status: AuthStatus.loading);

      expect(updated.status, AuthStatus.loading);
      expect(updated.errorMessage, 'Something went wrong');
    });

    test('clearUser removes the user', () {
      const state = AuthState(status: AuthStatus.authenticated);

      final updated = state.copyWith(clearUser: true);

      expect(updated.user, isNull);
    });

    test('clearError removes the error', () {
      const state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Authentication failed',
      );

      final updated = state.copyWith(clearError: true);

      expect(updated.errorMessage, isNull);
    });
  });
}
