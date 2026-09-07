import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:time_tracker/features/authentication/data/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.signInError,
    this.signUpError,
    this.googleSignInError,
    this.passwordResetError,
    this.signOutError,
    User? initialUser,
  }) : _currentUser = initialUser;

  final Object? signInError;
  final Object? signUpError;
  final Object? googleSignInError;
  final Object? passwordResetError;
  final Object? signOutError;

  User? _currentUser;

  final _authStateController = StreamController<User?>.broadcast();

  bool signInCalled = false;
  bool signUpCalled = false;
  bool googleSignInCalled = false;
  bool passwordResetCalled = false;
  bool signOutCalled = false;

  String? lastEmail;
  String? lastPassword;

  @override
  Stream<User?> get authStateChanges => _authStateController.stream;

  @override
  User? get currentUser => _currentUser;

  @override
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    signInCalled = true;
    lastEmail = email;
    lastPassword = password;

    if (signInError != null) {
      throw signInError!;
    }

    return _unsupportedUserCredential();
  }

  @override
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    signUpCalled = true;
    lastEmail = email;
    lastPassword = password;

    if (signUpError != null) {
      throw signUpError!;
    }

    return _unsupportedUserCredential();
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    googleSignInCalled = true;

    if (googleSignInError != null) {
      throw googleSignInError!;
    }

    return _unsupportedUserCredential();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    passwordResetCalled = true;
    lastEmail = email;

    if (passwordResetError != null) {
      throw passwordResetError!;
    }
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;

    if (signOutError != null) {
      throw signOutError!;
    }

    _currentUser = null;
    _authStateController.add(null);
  }

  void emitAuthState(User? user) {
    _currentUser = user;
    _authStateController.add(user);
  }

  Future<void> dispose() async {
    await _authStateController.close();
  }

  UserCredential _unsupportedUserCredential() {
    throw UnimplementedError(
      'FakeAuthRepository does not create real UserCredential objects.',
    );
  }
}
