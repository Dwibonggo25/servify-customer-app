import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../../../libraries/core/localization/language_controller.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../domain/repositories/account_security_repository.dart';
import 'account_security_state.dart';

final class AccountSecurityCubit extends Cubit<AccountSecurityState> {
  AccountSecurityCubit(this._repository) : super(const AccountSecurityState());

  final AccountSecurityRepository _repository;

  Future<void> load() async {
    emit(const AccountSecurityState(status: AccountSecurityStatus.loading));
    try {
      final info = await _repository.getSecurityInfo();
      emit(
        AccountSecurityState(status: AccountSecurityStatus.ready, info: info),
      );
    } catch (_) {
      emit(
        AccountSecurityState(
          status: AccountSecurityStatus.failure,
          message: _translate(LanguageKeys.accountSecurityLoadFailed),
        ),
      );
    }
  }

  Future<void> changePassword({
    required String newPassword,
    String? currentPassword,
  }) async {
    await _perform(
      AccountSecurityAction.changePassword,
      () => _repository.changePassword(
        newPassword: newPassword,
        currentPassword: currentPassword,
      ),
      LanguageKeys.passwordChanged,
    );
  }

  Future<void> signOutAllDevices() async {
    await _perform(
      AccountSecurityAction.signOutAllDevices,
      _repository.signOutAllDevices,
      LanguageKeys.allSessionsSignedOut,
    );
  }

  Future<void> deleteAccount({String? currentPassword}) async {
    await _perform(
      AccountSecurityAction.deleteAccount,
      () => _repository.deleteAccount(currentPassword: currentPassword),
      LanguageKeys.accountDeleted,
    );
  }

  void clearFeedback() {
    emit(
      state.copyWith(
        status: AccountSecurityStatus.ready,
        action: AccountSecurityAction.none,
      ),
    );
  }

  Future<void> _perform(
    AccountSecurityAction action,
    Future<void> Function() operation,
    String successMessageKey,
  ) async {
    emit(
      state.copyWith(status: AccountSecurityStatus.submitting, action: action),
    );
    try {
      await operation();
      emit(
        state.copyWith(
          status: AccountSecurityStatus.success,
          action: action,
          message: _translate(successMessageKey),
        ),
      );
    } on AuthException catch (error) {
      emit(
        state.copyWith(
          status: AccountSecurityStatus.failure,
          action: action,
          message: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AccountSecurityStatus.failure,
          action: action,
          message: _translate(LanguageKeys.securityActionFailed),
        ),
      );
    }
  }

  String _translate(String key) => LanguageController.instance.translate(key);
}
