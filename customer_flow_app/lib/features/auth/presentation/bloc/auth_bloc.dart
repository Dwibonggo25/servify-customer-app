import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../../../libraries/core/localization/language_controller.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

final class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._authRepository) : super(const AuthState()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<SignOutRequested>(_onSignOutRequested);
  }

  final AuthRepository _authRepository;

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState(status: AuthSubmissionStatus.loading));
    try {
      await _authRepository.signIn(
        email: event.email,
        password: event.password,
      );
      emit(const AuthState(status: AuthSubmissionStatus.success));
    } on AuthException catch (error) {
      emit(
        AuthState(status: AuthSubmissionStatus.failure, message: error.message),
      );
    } catch (_) {
      emit(
        AuthState(
          status: AuthSubmissionStatus.failure,
          message: LanguageController.instance.translate(
            LanguageKeys.generalError,
          ),
        ),
      );
    }
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState(status: AuthSubmissionStatus.loading));
    try {
      final user = await _authRepository.register(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
      );
      emit(
        AuthState(
          status: AuthSubmissionStatus.success,
          message: user == null
              ? LanguageController.instance.translate(
                  LanguageKeys.accountCreatedConfirmEmail,
                )
              : LanguageController.instance.translate(
                  LanguageKeys.accountCreated,
                ),
          requiresEmailConfirmation: user == null,
        ),
      );
    } on AuthException catch (error) {
      emit(
        AuthState(status: AuthSubmissionStatus.failure, message: error.message),
      );
    } catch (_) {
      emit(
        AuthState(
          status: AuthSubmissionStatus.failure,
          message: LanguageController.instance.translate(
            LanguageKeys.registerFailed,
          ),
        ),
      );
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState(status: AuthSubmissionStatus.loading));
    try {
      await _authRepository.signOut();
      emit(const AuthState(status: AuthSubmissionStatus.success));
    } catch (_) {
      emit(
        AuthState(
          status: AuthSubmissionStatus.failure,
          message: LanguageController.instance.translate(
            LanguageKeys.logoutFailed,
          ),
        ),
      );
    }
  }
}
