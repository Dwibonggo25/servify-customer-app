import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/account_security_info.dart';
import '../../domain/repositories/account_security_repository.dart';

final class SupabaseAccountSecurityRepository
    implements AccountSecurityRepository {
  const SupabaseAccountSecurityRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<AccountSecurityInfo> getSecurityInfo() async {
    final user = _requireUser();
    final providers = <String>{};
    final metadataProviders = user.appMetadata['providers'];

    if (metadataProviders is List) {
      providers.addAll(metadataProviders.whereType<String>());
    }

    final primaryProvider = user.appMetadata['provider'];
    if (primaryProvider is String && primaryProvider.isNotEmpty) {
      providers.add(primaryProvider);
    }

    providers.addAll(
      (user.identities ?? const <UserIdentity>[]).map(
        (identity) => identity.provider,
      ),
    );

    return AccountSecurityInfo(
      email: user.email ?? '',
      isEmailVerified: user.emailConfirmedAt != null,
      providers: providers.isEmpty ? const ['email'] : providers.toList(),
    );
  }

  @override
  Future<void> changePassword({
    required String newPassword,
    String? currentPassword,
  }) async {
    _requireUser();
    await _client.auth.updateUser(
      UserAttributes(
        password: newPassword,
        currentPassword: _normalized(currentPassword),
      ),
    );
  }

  @override
  Future<void> signOutAllDevices() =>
      _client.auth.signOut(scope: SignOutScope.global);

  @override
  Future<void> deleteAccount({String? currentPassword}) async {
    final user = _requireUser();
    final info = await getSecurityInfo();

    if (info.usesPassword) {
      final password = _normalized(currentPassword);
      if (password == null) {
        throw const AuthException('Current password is required.');
      }
      await _client.auth.signInWithPassword(
        email: user.email ?? '',
        password: password,
      );
    }

    await _client.rpc<void>('delete_own_account');
    await _client.auth.signOut(scope: SignOutScope.global);
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthSessionMissingException();
    }
    return user;
  }

  String? _normalized(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
