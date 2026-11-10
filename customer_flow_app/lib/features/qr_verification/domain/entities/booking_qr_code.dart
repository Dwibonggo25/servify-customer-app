import 'package:equatable/equatable.dart';

enum BookingQrPurpose {
  arrival,
  completion;

  String get databaseValue => name;

  String get label => switch (this) {
    BookingQrPurpose.arrival => 'kedatangan',
    BookingQrPurpose.completion => 'penyelesaian',
  };
}

final class BookingQrCode extends Equatable {
  const BookingQrCode({
    required this.token,
    required this.purpose,
    required this.expiresAt,
  });

  final String token;
  final BookingQrPurpose purpose;
  final DateTime expiresAt;

  @override
  List<Object?> get props => [token, purpose, expiresAt];
}

final class QrVerificationResult extends Equatable {
  const QrVerificationResult({
    required this.success,
    required this.message,
    this.bookingStatus,
  });

  final bool success;
  final String message;
  final String? bookingStatus;

  @override
  List<Object?> get props => [success, message, bookingStatus];
}
