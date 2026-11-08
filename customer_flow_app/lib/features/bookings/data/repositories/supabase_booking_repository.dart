import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/booking_draft.dart';
import '../../domain/entities/booking_record.dart';
import '../../domain/repositories/booking_repository.dart';

final class SupabaseBookingRepository implements BookingRepository {
  const SupabaseBookingRepository(this._client);

  static const _selection =
      'id, booking_number, service_id, staff_id, service_name, service_price, '
      'customer_name, customer_phone, service_address, scheduled_at, '
      'payment_method, note, status, total_amount, created_at, '
      'services(icon_key, color_value)';

  final SupabaseClient _client;

  @override
  Future<BookingRecord> createBooking(BookingDraft draft) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Sesi telah berakhir.');
    final scheduledAt = _scheduledAt(draft.schedule, draft.timeLabel);
    final row = await _client
        .from('bookings')
        .insert({
          'customer_id': user.id,
          'service_id': draft.service.id,
          'customer_name': draft.customerName,
          'customer_phone': draft.phoneNumber,
          'service_address': draft.address,
          'scheduled_at': scheduledAt.toUtc().toIso8601String(),
          'payment_method': draft.paymentMethod == 'e_wallet'
              ? 'ewallet'
              : draft.paymentMethod,
          'note': draft.note.isEmpty ? null : draft.note,
          'status': 'pending',
        })
        .select(_selection)
        .single();
    return _mapBooking(row);
  }

  @override
  Future<List<BookingRecord>> getCustomerBookings() => _getBookings();

  @override
  Future<BookingRecord?> getCustomerBooking(String id) => _getBooking(id);

  @override
  Future<List<BookingRecord>> getStaffBookings() => _getBookings();

  @override
  Future<BookingRecord?> getStaffBooking(String id) => _getBooking(id);

  @override
  Future<void> respondToBooking(String id, {required bool accept}) {
    return _client.rpc<void>(
      'respond_to_booking',
      params: {'p_booking_id': id, 'p_accept': accept},
    );
  }

  @override
  Future<void> updateProgress(String id, String status) {
    return _client.rpc<void>(
      'update_booking_progress',
      params: {'p_booking_id': id, 'p_status': status},
    );
  }

  Future<List<BookingRecord>> _getBookings() async {
    final rows = await _client
        .from('bookings')
        .select(_selection)
        .order('created_at', ascending: false);
    return rows.map(_mapBooking).toList(growable: false);
  }

  Future<BookingRecord?> _getBooking(String id) async {
    final row = await _client
        .from('bookings')
        .select(_selection)
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;

    final historyRows = await _client
        .from('booking_status_history')
        .select('status, created_at')
        .eq('booking_id', id)
        .order('created_at');
    final history = historyRows
        .map(
          (entry) => BookingStatusEntry(
            status: entry['status'] as String,
            createdAt: DateTime.parse(entry['created_at'] as String).toLocal(),
          ),
        )
        .toList(growable: false);
    return _mapBooking(row, history: history);
  }

  BookingRecord _mapBooking(
    Map<String, dynamic> row, {
    List<BookingStatusEntry> history = const [],
  }) {
    final service = row['services'] as Map<String, dynamic>?;
    return BookingRecord(
      id: row['id'] as String,
      number: row['booking_number'] as String,
      serviceId: row['service_id'] as String,
      staffId: row['staff_id'] as String?,
      serviceName: row['service_name'] as String,
      servicePrice: (row['service_price'] as num).toInt(),
      customerName: row['customer_name'] as String,
      customerPhone: row['customer_phone'] as String,
      address: row['service_address'] as String,
      scheduledAt: DateTime.parse(row['scheduled_at'] as String).toLocal(),
      paymentMethod: row['payment_method'] as String,
      note: row['note'] as String?,
      status: row['status'] as String,
      totalAmount: (row['total_amount'] as num).toInt(),
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      icon: _iconFor(service?['icon_key'] as String?),
      color: Color((service?['color_value'] as num?)?.toInt() ?? 0xFF4F46E5),
      history: history,
    );
  }

  DateTime _scheduledAt(DateTime date, String timeLabel) {
    final parts = timeLabel.split('.');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts.first),
      int.parse(parts.last),
    );
  }

  IconData _iconFor(String? key) => switch (key) {
    'cleaning_services' => Icons.cleaning_services_rounded,
    'handyman' => Icons.handyman_rounded,
    'local_laundry_service' => Icons.local_laundry_service_rounded,
    'ac_unit' => Icons.ac_unit_rounded,
    'pest_control' => Icons.pest_control_rounded,
    _ => Icons.home_repair_service_rounded,
  };
}
