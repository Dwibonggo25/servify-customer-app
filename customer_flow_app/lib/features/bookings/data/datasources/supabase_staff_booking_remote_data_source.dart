import 'dart:async';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'staff_booking_remote_data_source.dart';

final class SupabaseStaffBookingRemoteDataSource
    implements StaffBookingRemoteDataSource {
  const SupabaseStaffBookingRemoteDataSource(this._client);

  static const _selection =
      'id, booking_number, service_id, staff_id, service_name, service_price, '
      'customer_name, customer_phone, service_address, scheduled_at, '
      'payment_method, note, status, total_amount, created_at, '
      'services(icon_key, image_url, color_value)';

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchBookings() async {
    final rows = await _client
        .from('bookings')
        .select(_selection)
        .order('created_at', ascending: false);
    return rows.map(Map<String, dynamic>.from).toList(growable: false);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchBookings() {
    late final StreamController<List<Map<String, dynamic>>> controller;
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
          final bookings = await fetchBookings();
          if (!closed) controller.add(bookings);
        } catch (error, stackTrace) {
          developer.log(
            'Gagal memuat pembaruan realtime pesanan staf',
            name: 'SupabaseStaffBookingRemoteDataSource',
            error: error,
            stackTrace: stackTrace,
          );
          if (!closed) controller.addError(error, stackTrace);
        }
      } while (reloadAgain && !closed);
      reloadRunning = false;
    }

    Future<void> connect() async {
      try {
        await _client.realtime.setAuth(
          _client.auth.currentSession?.accessToken,
        );
        if (closed) return;

        channel = _client
            .channel(
              'staff-bookings',
              opts: const RealtimeChannelConfig(private: true),
            )
            .onBroadcast(
              event: 'changed',
              callback: (_) => unawaited(reload()),
            );
        channel!.subscribe((status, error) {
          switch (status) {
            case RealtimeSubscribeStatus.subscribed:
              developer.log(
                'Realtime pesanan staf aktif',
                name: 'SupabaseStaffBookingRemoteDataSource',
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
      } catch (error, stackTrace) {
        if (!closed) controller.addError(error, stackTrace);
      }
    }

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () => unawaited(connect()),
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
  Future<Map<String, dynamic>?> fetchBooking(String id) async {
    final row = await _client
        .from('bookings')
        .select(_selection)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchBookingHistory(String id) async {
    final rows = await _client
        .from('booking_status_history')
        .select('status, created_at')
        .eq('booking_id', id)
        .order('created_at');
    return rows.map(Map<String, dynamic>.from).toList(growable: false);
  }

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
}
