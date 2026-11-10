import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/booking_qr_code.dart';
import '../../domain/entities/staff_location.dart';
import '../../domain/repositories/booking_qr_repository.dart';

final class SupabaseBookingQrRepository implements BookingQrRepository {
  const SupabaseBookingQrRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<BookingQrCode> getOrCreateQr({
    required String bookingId,
    required BookingQrPurpose purpose,
  }) async {
    final response = await _client.rpc<dynamic>(
      'get_or_create_booking_qr',
      params: {'p_booking_id': bookingId, 'p_purpose': purpose.databaseValue},
    );
    final row = _asMap(response);
    return BookingQrCode(
      token: row['token'] as String,
      purpose: BookingQrPurpose.values.byName(row['purpose'] as String),
      expiresAt: DateTime.parse(row['expires_at'] as String).toLocal(),
    );
  }

  @override
  Future<QrVerificationResult> verifyQr({
    required String bookingId,
    required String token,
    required StaffLocation location,
  }) async {
    final response = await _client.rpc<dynamic>(
      'verify_booking_qr',
      params: {
        'p_booking_id': bookingId,
        'p_token': token,
        'p_latitude': location.latitude,
        'p_longitude': location.longitude,
        'p_accuracy': location.accuracy,
      },
    );
    final row = _asMap(response);
    return QrVerificationResult(
      success: row['success'] as bool? ?? false,
      message: row['message'] as String? ?? 'QR tidak dapat diverifikasi.',
      bookingStatus: row['booking_status'] as String?,
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is List && value.isNotEmpty && value.first is Map) {
      return Map<String, dynamic>.from(value.first as Map);
    }
    throw const FormatException('Respons verifikasi QR tidak valid.');
  }
}
