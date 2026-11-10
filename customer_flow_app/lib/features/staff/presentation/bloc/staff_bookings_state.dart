import 'package:equatable/equatable.dart';

import '../../../bookings/domain/entities/booking_record.dart';

enum StaffBookingsStatus { initial, loading, success, failure }

final class StaffBookingsState extends Equatable {
  const StaffBookingsState({
    this.status = StaffBookingsStatus.initial,
    this.bookings = const [],
    this.message,
    this.refreshing = false,
  });

  final StaffBookingsStatus status;
  final List<BookingRecord> bookings;
  final String? message;
  final bool refreshing;

  List<BookingRecord> get available =>
      bookings.where((booking) => booking.isAvailable).toList(growable: false);

  List<BookingRecord> get active => bookings
      .where((booking) => !booking.isAvailable && !booking.isFinished)
      .toList(growable: false);

  List<BookingRecord> get incoming =>
      bookings.where((booking) => !booking.isFinished).toList(growable: false);

  List<BookingRecord> get history =>
      bookings.where((booking) => booking.isFinished).toList(growable: false);

  int get completedCount =>
      bookings.where((booking) => booking.status == 'completed').length;

  StaffBookingsState copyWith({
    StaffBookingsStatus? status,
    List<BookingRecord>? bookings,
    String? message,
    bool? refreshing,
  }) => StaffBookingsState(
    status: status ?? this.status,
    bookings: bookings ?? this.bookings,
    message: message,
    refreshing: refreshing ?? this.refreshing,
  );

  @override
  List<Object?> get props => [status, bookings, message, refreshing];
}
