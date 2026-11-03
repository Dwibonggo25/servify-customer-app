import '../../../services/domain/entities/service_item.dart';

final class BookingDraft {
  const BookingDraft({
    required this.service,
    required this.customerName,
    required this.phoneNumber,
    required this.address,
    required this.schedule,
    required this.timeLabel,
    required this.paymentMethod,
    this.note = '',
  });

  final ServiceItem service;
  final String customerName;
  final String phoneNumber;
  final String address;
  final DateTime schedule;
  final String timeLabel;
  final String paymentMethod;
  final String note;
}
