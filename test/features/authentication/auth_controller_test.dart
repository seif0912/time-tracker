import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:time_tracker/features/authentication/data/auth_providers.dart';
import 'package:time_tracker/features/authentication/domain/auth_state.dart';
import 'package:time_tracker/features/authentication/presentation/auth_controller.dart';

import 'fakes/fake_auth_repository.dart';

void main() {
  group('AuthController', () {
    late ProviderContainer container;
    late FakeAuthRepository repository;

    setUp(() {
      repository = FakeAuthRepository();

      container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );

      // Initialize the controller so its auth-state listener is active.
      container.read(authControllerProvider);
    });

    tearDown(() async {
      container.dispose();
      await repository.dispose();
    });

    test('starts with initial state', () {
      final state = container.read(authControllerProvider);

      expect(state.status, AuthStatus.initial);
      expect(state.isInitializing, isTrue);
    });

    test('becomes authenticated when auth state emits a user', () async {
      repository.emitAuthState(null);

      repository.emitAuthState(_FakeUser());

      await Future<void>.delayed(Duration.zero);

      final state = container.read(authControllerProvider);

      expect(state.status, AuthStatus.authenticated);
      expect(state.user, isNotNull);
      expect(state.isAuthenticated, isTrue);
    });

    test('becomes unauthenticated when auth state emits null', () async {
      repository.emitAuthState(null);

      await Future<void>.delayed(Duration.zero);

      final state = container.read(authControllerProvider);

      expect(state.status, AuthStatus.unauthenticated);
      expect(state.user, isNull);
    });

    test('signIn calls repository with credentials', () async {
      await container
          .read(authControllerProvider.notifier)
          .signIn(email: ' test@example.com ', password: 'password123');

      expect(repository.signInCalled, isTrue);
      expect(repository.lastEmail, ' test@example.com ');
      expect(repository.lastPassword, 'password123');
    });

    test('signIn sets error state when repository fails', () async {
      final failingRepository = FakeAuthRepository(
        signInError: FirebaseAuthException(code: 'invalid-credential'),
      );

      final testContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(failingRepository),
        ],
      );

      addTearDown(() async {
        testContainer.dispose();
        await failingRepository.dispose();
      });

      final controller = testContainer.read(authControllerProvider.notifier);

      await controller.signIn(
        email: 'test@example.com',
        password: 'wrong-password',
      );

      final state = testContainer.read(authControllerProvider);

      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, 'The email or password is incorrect.');
    });

    test('signUp calls repository with credentials', () async {
      await container
          .read(authControllerProvider.notifier)
          .signUp(email: 'test@example.com', password: 'password123');

      expect(repository.signUpCalled, isTrue);
      expect(repository.lastEmail, 'test@example.com');
      expect(repository.lastPassword, 'password123');
    });

    test('signUp maps Firebase errors', () async {
      final failingRepository = FakeAuthRepository(
        signUpError: FirebaseAuthException(code: 'email-already-in-use'),
      );

      final testContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(failingRepository),
        ],
      );

      addTearDown(() async {
        testContainer.dispose();
        await failingRepository.dispose();
      });

      await testContainer
          .read(authControllerProvider.notifier)
          .signUp(email: 'test@example.com', password: 'password123');

      final state = testContainer.read(authControllerProvider);

      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, 'An account already exists with this email.');
    });

    test('Google sign-in calls repository', () async {
      await container.read(authControllerProvider.notifier).signInWithGoogle();

      expect(repository.googleSignInCalled, isTrue);
    });

    test('password reset calls repository', () async {
      await container
          .read(authControllerProvider.notifier)
          .sendPasswordResetEmail('test@example.com');

      expect(repository.passwordResetCalled, isTrue);
      expect(repository.lastEmail, 'test@example.com');

      final state = container.read(authControllerProvider);

      expect(state.status, AuthStatus.unauthenticated);
    });

    test('password reset maps Firebase errors', () async {
      final failingRepository = FakeAuthRepository(
        passwordResetError: FirebaseAuthException(code: 'user-not-found'),
      );

      final testContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(failingRepository),
        ],
      );

      addTearDown(() async {
        testContainer.dispose();
        await failingRepository.dispose();
      });

      await testContainer
          .read(authControllerProvider.notifier)
          .sendPasswordResetEmail('missing@example.com');

      final state = testContainer.read(authControllerProvider);

      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, 'No account was found with this email.');
    });

    test('signOut calls repository', () async {
      await container.read(authControllerProvider.notifier).signOut();

      expect(repository.signOutCalled, isTrue);
    });

    test('signOut maps Firebase errors', () async {
      final failingRepository = FakeAuthRepository(
        signOutError: FirebaseAuthException(code: 'network-request-failed'),
      );

      final testContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(failingRepository),
        ],
      );

      addTearDown(() async {
        testContainer.dispose();
        await failingRepository.dispose();
      });

      await testContainer.read(authControllerProvider.notifier).signOut();

      final state = testContainer.read(authControllerProvider);

      expect(state.status, AuthStatus.error);
      expect(
        state.errorMessage,
        'Network error. Please check your connection.',
      );
    });
  });
}

/// Minimal fake User object.
///
/// The controller only needs a non-null User to transition into
/// authenticated state, so the test doesn't need a real Firebase user.
class _FakeUser extends Fake implements User {}
