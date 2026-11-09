import 'package:equatable/equatable.dart';

import '../../domain/entities/booking_record.dart';

enum BookingDetailStatus {
  initial,
  loading,
  success,
  submitting,
  actionSuccess,
  failure,
}

final class BookingDetailState extends Equatable {
  const BookingDetailState({
    this.status = BookingDetailStatus.initial,
    this.booking,
    this.message,
    this.shouldPop = false,
    this.realtimeConnected = false,
    this.realtimeFailed = false,
  });

  final BookingDetailStatus status;
  final BookingRecord? booking;
  final String? message;
  final bool shouldPop;
  final bool realtimeConnected;
  final bool realtimeFailed;

  bool get isLoading =>
      status == BookingDetailStatus.initial ||
      (status == BookingDetailStatus.loading && booking == null);
  bool get isSubmitting => status == BookingDetailStatus.submitting;

  BookingDetailState copyWith({
    BookingDetailStatus? status,
    BookingRecord? booking,
    String? message,
    bool shouldPop = false,
    bool? realtimeConnected,
    bool? realtimeFailed,
  }) => BookingDetailState(
    status: status ?? this.status,
    booking: booking ?? this.booking,
    message: message,
    shouldPop: shouldPop,
    realtimeConnected: realtimeConnected ?? this.realtimeConnected,
    realtimeFailed: realtimeFailed ?? this.realtimeFailed,
  );

  @override
  List<Object?> get props => [
    status,
    booking,
    message,
    shouldPop,
    realtimeConnected,
    realtimeFailed,
  ];
}
