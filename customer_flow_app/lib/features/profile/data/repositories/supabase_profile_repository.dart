import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/customer_profile.dart';
import '../../domain/repositories/profile_repository.dart';

final class SupabaseProfileRepository implements ProfileRepository {
  const SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<CustomerProfile> getProfile() async {
    final user = _requireUser();
    final data = await _client
        .from('profiles')
        .select('id, full_name, phone, avatar_url, role')
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) {
      final fallbackName = _metadataName(user);
      final inserted = await _client
          .from('profiles')
          .insert({
            'id': user.id,
            'full_name': fallbackName,
            'phone': user.userMetadata?['phone'] as String?,
          })
          .select('id, full_name, phone, avatar_url, role')
          .single();
      return _mapProfile(inserted, user.email ?? '');
    }

    return _mapProfile(data, user.email ?? '');
  }

  @override
  Future<CustomerProfile> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    final user = _requireUser();
    final normalizedName = fullName.trim();
    final normalizedPhone = phone.trim();

    final data = await _client
        .from('profiles')
        .update({
          'full_name': normalizedName,
          'phone': normalizedPhone.isEmpty ? null : normalizedPhone,
        })
        .eq('id', user.id)
        .select('id, full_name, phone, avatar_url, role')
        .single();

    await _client.auth.updateUser(
      UserAttributes(data: {'full_name': normalizedName}),
    );

    return _mapProfile(data, user.email ?? '');
  }

  @override
  Future<CustomerProfile> uploadAvatar({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final user = _requireUser();
    final extension = _normalizedExtension(fileExtension);
    final fileName = 'avatar.$extension';
    final path = '${user.id}/$fileName';
    final bucket = _client.storage.from('avatars');

    final existingFiles = await bucket.list(path: user.id);
    await bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: _contentType(extension),
        upsert: true,
      ),
    );

    final oldPaths = existingFiles
        .where(
          (file) => file.name.startsWith('avatar.') && file.name != fileName,
        )
        .map((file) => '${user.id}/${file.name}')
        .toList(growable: false);
    if (oldPaths.isNotEmpty) await bucket.remove(oldPaths);

    final version = DateTime.now().millisecondsSinceEpoch;
    final avatarUrl = '${bucket.getPublicUrl(path)}?v=$version';
    final data = await _client
        .from('profiles')
        .update({'avatar_url': avatarUrl})
        .eq('id', user.id)
        .select('id, full_name, phone, avatar_url, role')
        .single();

    await _client.auth.updateUser(
      UserAttributes(data: {'avatar_url': avatarUrl}),
    );
    return _mapProfile(data, user.email ?? '');
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Sesi berakhir. Silakan masuk kembali.');
    }
    return user;
  }

  String _metadataName(User user) {
    final value = user.userMetadata?['full_name'] as String?;
    if (value != null && value.trim().isNotEmpty) return value.trim();
    final email = user.email ?? '';
    return email.contains('@') ? email.split('@').first : 'Customer';
  }

  CustomerProfile _mapProfile(Map<String, dynamic> data, String email) {
    return CustomerProfile(
      id: data['id'] as String,
      email: email,
      fullName: data['full_name'] as String? ?? '',
      phone: data['phone'] as String?,
      avatarUrl: data['avatar_url'] as String?,
      role: data['role'] as String? ?? 'customer',
    );
  }

  String _normalizedExtension(String value) {
    final extension = value.toLowerCase().replaceAll('.', '').trim();
    return switch (extension) {
      'png' || 'webp' || 'heic' || 'heif' => extension,
      _ => 'jpg',
    };
  }

  String _contentType(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => 'image/jpeg',
    };
  }
}
