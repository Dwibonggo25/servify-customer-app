import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/address_draft.dart';
import '../../domain/entities/customer_address.dart';
import '../../domain/repositories/address_repository.dart';

final class SupabaseAddressRepository implements AddressRepository {
  const SupabaseAddressRepository(this._client);

  static const _columns =
      'id, label, recipient_name, phone, address_line, notes, latitude, '
      'longitude, is_default';

  final SupabaseClient _client;

  @override
  Future<List<CustomerAddress>> getAddresses() async {
    final user = _requireUser();
    final rows = await _client
        .from('customer_addresses')
        .select(_columns)
        .eq('user_id', user.id)
        .order('is_default', ascending: false)
        .order('updated_at', ascending: false);

    return rows.map(_mapAddress).toList(growable: false);
  }

  @override
  Future<CustomerAddress> createAddress(AddressDraft draft) async {
    final user = _requireUser();
    final current = await getAddresses();
    final shouldBeDefault = draft.isDefault || current.isEmpty;
    if (shouldBeDefault) await _clearDefaultAddresses(user.id);

    final row = await _client
        .from('customer_addresses')
        .insert({
          'user_id': user.id,
          ..._draftData(draft, isDefault: shouldBeDefault),
        })
        .select(_columns)
        .single();
    return _mapAddress(row);
  }

  @override
  Future<CustomerAddress> updateAddress(String id, AddressDraft draft) async {
    final user = _requireUser();
    if (draft.isDefault) await _clearDefaultAddresses(user.id, exceptId: id);

    final row = await _client
        .from('customer_addresses')
        .update(_draftData(draft))
        .eq('id', id)
        .eq('user_id', user.id)
        .select(_columns)
        .single();
    return _mapAddress(row);
  }

  @override
  Future<void> setDefaultAddress(String id) async {
    final user = _requireUser();
    await _clearDefaultAddresses(user.id, exceptId: id);
    await _client
        .from('customer_addresses')
        .update({'is_default': true})
        .eq('id', id)
        .eq('user_id', user.id);
  }

  @override
  Future<void> deleteAddress(String id) async {
    final user = _requireUser();
    final addresses = await getAddresses();
    final removed = addresses.where((address) => address.id == id).firstOrNull;

    await _client
        .from('customer_addresses')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);

    if (removed?.isDefault == true) {
      final replacement = addresses
          .where((address) => address.id != id)
          .firstOrNull;
      if (replacement != null) await setDefaultAddress(replacement.id);
    }
  }

  Future<void> _clearDefaultAddresses(String userId, {String? exceptId}) async {
    var query = _client
        .from('customer_addresses')
        .update({'is_default': false})
        .eq('user_id', userId)
        .eq('is_default', true);
    if (exceptId != null) query = query.neq('id', exceptId);
    await query;
  }

  Map<String, dynamic> _draftData(AddressDraft draft, {bool? isDefault}) => {
    'label': draft.label.trim(),
    'recipient_name': draft.recipientName.trim(),
    'phone': draft.phone.trim(),
    'address_line': draft.addressLine.trim(),
    'notes': _nullableText(draft.notes),
    'latitude': draft.latitude,
    'longitude': draft.longitude,
    'is_default': isDefault ?? draft.isDefault,
  };

  CustomerAddress _mapAddress(Map<String, dynamic> row) => CustomerAddress(
    id: row['id'] as String,
    label: row['label'] as String? ?? '',
    recipientName: row['recipient_name'] as String? ?? '',
    phone: row['phone'] as String? ?? '',
    addressLine: row['address_line'] as String? ?? '',
    notes: row['notes'] as String?,
    latitude: (row['latitude'] as num?)?.toDouble(),
    longitude: (row['longitude'] as num?)?.toDouble(),
    isDefault: row['is_default'] as bool? ?? false,
  );

  String? _nullableText(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Sesi berakhir. Silakan masuk kembali.');
    }
    return user;
  }
}
