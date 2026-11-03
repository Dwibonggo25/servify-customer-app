import 'dart:async';

import 'package:customer_flow_app/app/session/app_session_controller.dart';
import 'package:customer_flow_app/features/auth/domain/entities/app_user.dart';
import 'package:customer_flow_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:customer_flow_app/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSessionController', () {
    test('sends a first-time user to onboarding', () {
      final auth = _FakeAuthRepository();
      final onboarding = _FakeOnboardingRepository();
      final controller = AppSessionController(
        authRepository: auth,
        onboardingRepository: onboarding,
      );

      expect(controller.destinationAfterSplash, '/onboarding');

      controller.dispose();
      auth.dispose();
    });

    test('sends an authenticated returning user to home', () {
      final auth = _FakeAuthRepository(
        currentUser: const AppUser(id: '1', email: 'customer@example.com'),
      );
      final onboarding = _FakeOnboardingRepository(isCompleted: true);
      final controller = AppSessionController(
        authRepository: auth,
        onboardingRepository: onboarding,
      );

      expect(controller.destinationAfterSplash, '/home');

      controller.dispose();
      auth.dispose();
    });

    test('completing onboarding persists the setting', () async {
      final auth = _FakeAuthRepository();
      final onboarding = _FakeOnboardingRepository();
      final controller = AppSessionController(
        authRepository: auth,
        onboardingRepository: onboarding,
      );

      await controller.completeOnboarding();

      expect(onboarding.isCompleted, isTrue);
      expect(controller.destinationAfterSplash, '/login');

      controller.dispose();
      auth.dispose();
    });
  });
}

final class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.currentUser});

  final StreamController<AppUser?> _controller = StreamController.broadcast();

  @override
  AppUser? currentUser;

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  Future<AppUser?> register({
    required String fullName,
    required String email,
    required String password,
  }) async => null;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async => AppUser(id: '1', email: email);

  @override
  Future<void> signOut() async {}

  void dispose() => _controller.close();
}

final class _FakeOnboardingRepository implements OnboardingRepository {
  _FakeOnboardingRepository({this.isCompleted = false});

  @override
  bool isCompleted;

  @override
  Future<void> complete() async => isCompleted = true;
}
