import 'package:equatable/equatable.dart';

import '../../domain/entities/account_security_info.dart';

enum AccountSecurityStatus {
  initial,
  loading,
  ready,
  submitting,
  success,
  failure,
}

enum AccountSecurityAction {
  none,
  changePassword,
  signOutAllDevices,
  deleteAccount,
}

final class AccountSecurityState extends Equatable {
  const AccountSecurityState({
    this.status = AccountSecurityStatus.initial,
    this.action = AccountSecurityAction.none,
    this.info,
    this.message,
  });

  final AccountSecurityStatus status;
  final AccountSecurityAction action;
  final AccountSecurityInfo? info;
  final String? message;

  bool get isLoading => status == AccountSecurityStatus.loading;
  bool get isSubmitting => status == AccountSecurityStatus.submitting;

  AccountSecurityState copyWith({
    AccountSecurityStatus? status,
    AccountSecurityAction? action,
    AccountSecurityInfo? info,
    String? message,
  }) {
    return AccountSecurityState(
      status: status ?? this.status,
      action: action ?? this.action,
      info: info ?? this.info,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, action, info, message];
}
