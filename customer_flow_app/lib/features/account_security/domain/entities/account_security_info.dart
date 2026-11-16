import 'package:equatable/equatable.dart';

final class AccountSecurityInfo extends Equatable {
  const AccountSecurityInfo({
    required this.email,
    required this.isEmailVerified,
    required this.providers,
  });

  final String email;
  final bool isEmailVerified;
  final List<String> providers;

  bool get usesPassword => providers.contains('email');

  @override
  List<Object?> get props => [email, isEmailVerified, providers];
}
