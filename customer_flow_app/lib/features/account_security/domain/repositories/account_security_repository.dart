import '../entities/account_security_info.dart';

abstract interface class AccountSecurityRepository {
  Future<AccountSecurityInfo> getSecurityInfo();

  Future<void> changePassword({
    required String newPassword,
    String? currentPassword,
  });

  Future<void> signOutAllDevices();

  Future<void> deleteAccount({String? currentPassword});
}
