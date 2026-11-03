import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/onboarding/domain/repositories/onboarding_repository.dart';

final class AppSessionController extends ChangeNotifier {
  AppSessionController({
    required AuthRepository authRepository,
    required OnboardingRepository onboardingRepository,
  }) : _authRepository = authRepository,
       _onboardingRepository = onboardingRepository,
       _currentUser = authRepository.currentUser,
       _onboardingCompleted = onboardingRepository.isCompleted {
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  final AuthRepository _authRepository;
  final OnboardingRepository _onboardingRepository;
  late final StreamSubscription<AppUser?> _authSubscription;

  AppUser? _currentUser;
  bool _onboardingCompleted;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get onboardingCompleted => _onboardingCompleted;

  String get destinationAfterSplash {
    if (!_onboardingCompleted) return '/onboarding';
    return isAuthenticated ? '/home' : '/login';
  }

  Future<void> completeOnboarding() async {
    await _onboardingRepository.complete();
    _onboardingCompleted = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
