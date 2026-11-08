import 'package:equatable/equatable.dart';

final class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.bookingId,
    this.readAt,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final String? bookingId;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    type,
    createdAt,
    bookingId,
    readAt,
  ];
}
