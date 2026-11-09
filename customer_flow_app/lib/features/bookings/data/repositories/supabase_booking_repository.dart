import 'dart:async';
import 'dart:developer' as developer;

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
      'services(icon_key, image_url, color_value)';

  final SupabaseClient _client;

  @override
  Future<BookingRecord> createBooking(BookingDraft draft) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Sesi telah berakhir.');
    final scheduledAt = _scheduledAt(draft.schedule, draft.timeLabel);
    developer.log(
      'Membuat pesanan service=${draft.service.id}, '
      'scheduledAt=${scheduledAt.toUtc().toIso8601String()}, '
      'now=${DateTime.now().toUtc().toIso8601String()}',
      name: 'SupabaseBookingRepository',
    );
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
  Stream<BookingRecord> watchCustomerBooking(String id) {
    late final StreamController<BookingRecord> controller;
    RealtimeChannel? channel;
    var closed = false;
    var reloadRunning = false;
    var reloadAgain = false;

    Future<void> reload() async {
      if (closed) return;
      if (reloadRunning) {
        reloadAgain = true;
        return;
      }

      reloadRunning = true;
      do {
        reloadAgain = false;
        try {
          final booking = await _getBooking(id);
          if (!closed && booking != null) controller.add(booking);
        } catch (error, stackTrace) {
          developer.log(
            'Gagal memuat pembaruan realtime pesanan $id',
            name: 'SupabaseBookingRepository',
            error: error,
            stackTrace: stackTrace,
          );
          if (!closed) controller.addError(error, stackTrace);
        }
      } while (reloadAgain && !closed);
      reloadRunning = false;
    }

    controller = StreamController<BookingRecord>(
      onListen: () {
        channel = _client
            .channel(
              'customer-booking:$id:${DateTime.now().microsecondsSinceEpoch}',
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'bookings',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'id',
                value: id,
              ),
              callback: (_) => unawaited(reload()),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'booking_status_history',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'booking_id',
                value: id,
              ),
              callback: (_) => unawaited(reload()),
            );
        channel!.subscribe((status, error) {
          switch (status) {
            case RealtimeSubscribeStatus.subscribed:
              developer.log(
                'Realtime tracking aktif untuk pesanan $id',
                name: 'SupabaseBookingRepository',
              );
              unawaited(reload());
              return;
            case RealtimeSubscribeStatus.channelError:
            case RealtimeSubscribeStatus.timedOut:
            case RealtimeSubscribeStatus.closed:
              if (!closed) {
                controller.addError(
                  StateError(
                    'Koneksi realtime ${status.name}: ${error ?? '-'}',
                  ),
                );
              }
          }
        });
      },
      onCancel: () async {
        closed = true;
        final activeChannel = channel;
        if (activeChannel != null) {
          await _client.removeChannel(activeChannel);
        }
      },
    );

    return controller.stream;
  }

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

  @override
  Future<void> cancelBooking(String id) {
    return _client.rpc<void>(
      'cancel_customer_booking',
      params: {'p_booking_id': id},
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
      imageUrl: (service?['image_url'] as String?)?.trim().isNotEmpty == true
          ? (service!['image_url'] as String).trim()
          : null,
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
