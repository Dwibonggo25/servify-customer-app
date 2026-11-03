import '../entities/app_user.dart';

abstract interface class AuthRepository {
  AppUser? get currentUser;

  Stream<AppUser?> get authStateChanges;

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser?> register({
    required String fullName,
    required String email,
    required String password,
  });

  Future<void> signOut();
}
