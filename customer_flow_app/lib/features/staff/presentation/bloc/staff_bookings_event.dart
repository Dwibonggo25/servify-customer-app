import 'package:equatable/equatable.dart';

import '../../../bookings/domain/entities/booking_record.dart';

sealed class StaffBookingsEvent extends Equatable {
  const StaffBookingsEvent();

  @override
  List<Object?> get props => const [];
}

final class StaffBookingsRequested extends StaffBookingsEvent {
  const StaffBookingsRequested({this.refresh = false});

  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

final class StaffBookingsRealtimeStarted extends StaffBookingsEvent {
  const StaffBookingsRealtimeStarted();
}

final class StaffBookingsRealtimeUpdated extends StaffBookingsEvent {
  const StaffBookingsRealtimeUpdated(this.bookings);

  final List<BookingRecord> bookings;

  @override
  List<Object?> get props => [bookings];
}

final class StaffBookingsRealtimeFailed extends StaffBookingsEvent {
  const StaffBookingsRealtimeFailed(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;

  @override
  List<Object?> get props => [error, stackTrace];
}
