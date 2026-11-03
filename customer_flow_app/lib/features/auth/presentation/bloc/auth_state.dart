import 'package:equatable/equatable.dart';

enum AuthSubmissionStatus { initial, loading, success, failure }

final class AuthState extends Equatable {
  const AuthState({
    this.status = AuthSubmissionStatus.initial,
    this.message,
    this.requiresEmailConfirmation = false,
  });

  final AuthSubmissionStatus status;
  final String? message;
  final bool requiresEmailConfirmation;

  bool get isLoading => status == AuthSubmissionStatus.loading;

  AuthState copyWith({
    AuthSubmissionStatus? status,
    String? message,
    bool? requiresEmailConfirmation,
  }) {
    return AuthState(
      status: status ?? this.status,
      message: message,
      requiresEmailConfirmation:
          requiresEmailConfirmation ?? this.requiresEmailConfirmation,
    );
  }

  @override
  List<Object?> get props => [status, message, requiresEmailConfirmation];
}
