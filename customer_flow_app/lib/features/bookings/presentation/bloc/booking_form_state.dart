import 'package:equatable/equatable.dart';

import '../../domain/entities/booking_record.dart';

enum BookingFormStatus { initial, submitting, success, failure }

final class BookingFormState extends Equatable {
  const BookingFormState({
    this.status = BookingFormStatus.initial,
    this.booking,
    this.message,
  });

  final BookingFormStatus status;
  final BookingRecord? booking;
  final String? message;

  bool get isSubmitting => status == BookingFormStatus.submitting;

  @override
  List<Object?> get props => [status, booking, message];
}
