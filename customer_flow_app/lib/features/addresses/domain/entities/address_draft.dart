import 'package:equatable/equatable.dart';

final class AddressDraft extends Equatable {
  const AddressDraft({
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.addressLine,
    required this.isDefault,
    this.notes,
    this.latitude,
    this.longitude,
  });

  final String label;
  final String recipientName;
  final String phone;
  final String addressLine;
  final String? notes;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  @override
  List<Object?> get props => [
    label,
    recipientName,
    phone,
    addressLine,
    notes,
    latitude,
    longitude,
    isDefault,
  ];
}
