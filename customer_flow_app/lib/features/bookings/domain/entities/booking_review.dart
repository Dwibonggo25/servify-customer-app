import 'package:equatable/equatable.dart';

final class BookingReview extends Equatable {
  const BookingReview({
    required this.id,
    required this.bookingId,
    required this.serviceId,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
    this.comment,
  });

  final String id;
  final String bookingId;
  final String serviceId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    bookingId,
    serviceId,
    rating,
    comment,
    createdAt,
    updatedAt,
  ];
}
