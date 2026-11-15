import 'package:equatable/equatable.dart';

import '../../domain/entities/booking_record.dart';
import '../../domain/entities/booking_review.dart';

enum BookingDetailStatus {
  initial,
  loading,
  success,
  submitting,
  actionSuccess,
  failure,
}

enum BookingDetailFeedback {
  bookingRejected,
  bookingAccepted,
  progressUpdated,
  bookingCancelled,
  reviewSaved,
}

final class BookingDetailState extends Equatable {
  const BookingDetailState({
    this.status = BookingDetailStatus.initial,
    this.booking,
    this.review,
    this.message,
    this.feedback,
    this.shouldPop = false,
    this.realtimeConnected = false,
    this.realtimeFailed = false,
  });

  final BookingDetailStatus status;
  final BookingRecord? booking;
  final BookingReview? review;
  final String? message;
  final BookingDetailFeedback? feedback;
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
    BookingReview? review,
    String? message,
    BookingDetailFeedback? feedback,
    bool shouldPop = false,
    bool? realtimeConnected,
    bool? realtimeFailed,
  }) => BookingDetailState(
    status: status ?? this.status,
    booking: booking ?? this.booking,
    review: review ?? this.review,
    message: message,
    feedback: feedback,
    shouldPop: shouldPop,
    realtimeConnected: realtimeConnected ?? this.realtimeConnected,
    realtimeFailed: realtimeFailed ?? this.realtimeFailed,
  );

  @override
  List<Object?> get props => [
    status,
    booking,
    review,
    message,
    feedback,
    shouldPop,
    realtimeConnected,
    realtimeFailed,
  ];
}
