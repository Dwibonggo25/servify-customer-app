import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

final class BookingStatusEntry extends Equatable {
  const BookingStatusEntry({required this.status, required this.createdAt});

  final String status;
  final DateTime createdAt;

  @override
  List<Object?> get props => [status, createdAt];
}

final class BookingRecord extends Equatable {
  const BookingRecord({
    required this.id,
    required this.number,
    required this.serviceId,
    required this.serviceName,
    required this.servicePrice,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.scheduledAt,
    required this.paymentMethod,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.icon,
    required this.color,
    this.staffId,
    this.note,
    this.history = const [],
  });

  final String id;
  final String number;
  final String serviceId;
  final String serviceName;
  final int servicePrice;
  final String customerName;
  final String customerPhone;
  final String address;
  final DateTime scheduledAt;
  final String paymentMethod;
  final String status;
  final int totalAmount;
  final DateTime createdAt;
  final IconData icon;
  final Color color;
  final String? staffId;
  final String? note;
  final List<BookingStatusEntry> history;

  bool get isFinished => status == 'completed' || status == 'cancelled';
  bool get isAvailable => status == 'pending' && staffId == null;

  @override
  List<Object?> get props => [
    id,
    number,
    serviceId,
    serviceName,
    servicePrice,
    customerName,
    customerPhone,
    address,
    scheduledAt,
    paymentMethod,
    status,
    totalAmount,
    createdAt,
    staffId,
    note,
    history,
  ];
}
