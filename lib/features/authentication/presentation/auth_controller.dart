import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_providers.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  StreamSubscription<User?>? _authSubscription;

  @override
  AuthState build() {
    final repository = ref.read(authRepositoryProvider);

    ref.onDispose(() {
      _authSubscription?.cancel();
    });

    _listenToAuthState(repository);

    return const AuthState();
  }

  void _listenToAuthState(AuthRepository repository) {
    _authSubscription = repository.authStateChanges.listen(
      (user) {
        if (user != null) {
          state = AuthState(status: AuthStatus.authenticated, user: user);
        } else {
          state = const AuthState(status: AuthStatus.unauthenticated);
        }
      },
      onError: (error) {
        state = AuthState(
          status: AuthStatus.error,
          errorMessage: error.toString(),
        );
      },
    );
  }

  Future<void> signUp({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      await ref
          .read(authRepositoryProvider)
          .signUpWithEmail(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseAuthError(e),
      );
    } catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithEmail(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseAuthError(e),
      );
    } catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseAuthError(e),
      );
    } catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordResetEmail(email: email);

      state = state.copyWith(status: AuthStatus.unauthenticated);
    } on FirebaseAuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseAuthError(e),
      );
    } catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      await ref.read(authRepositoryProvider).signOut();
    } on FirebaseAuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseAuthError(e),
      );
    } catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  String _mapFirebaseAuthError(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account was found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'The email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
