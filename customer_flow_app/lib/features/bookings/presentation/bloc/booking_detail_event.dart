import 'package:equatable/equatable.dart';

import '../../domain/entities/booking_record.dart';

sealed class BookingDetailEvent extends Equatable {
  const BookingDetailEvent();

  @override
  List<Object?> get props => const [];
}

final class BookingDetailRequested extends BookingDetailEvent {
  const BookingDetailRequested();
}

final class BookingResponseSubmitted extends BookingDetailEvent {
  const BookingResponseSubmitted({required this.accept});

  final bool accept;

  @override
  List<Object?> get props => [accept];
}

final class BookingProgressSubmitted extends BookingDetailEvent {
  const BookingProgressSubmitted(this.status);

  final String status;

  @override
  List<Object?> get props => [status];
}

final class BookingCancellationSubmitted extends BookingDetailEvent {
  const BookingCancellationSubmitted();
}

final class BookingRealtimeUpdated extends BookingDetailEvent {
  const BookingRealtimeUpdated(this.booking);

  final BookingRecord booking;

  @override
  List<Object?> get props => [booking];
}

final class BookingRealtimeDisconnected extends BookingDetailEvent {
  const BookingRealtimeDisconnected(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}
