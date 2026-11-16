import 'package:equatable/equatable.dart';

import '../../domain/entities/customer_address.dart';

enum AddressStatus { initial, loading, loaded, saving, failure }

final class AddressState extends Equatable {
  const AddressState({
    this.status = AddressStatus.initial,
    this.addresses = const [],
    this.message,
  });

  final AddressStatus status;
  final List<CustomerAddress> addresses;
  final String? message;

  bool get isLoading =>
      status == AddressStatus.initial || status == AddressStatus.loading;
  bool get isSaving => status == AddressStatus.saving;

  AddressState copyWith({
    AddressStatus? status,
    List<CustomerAddress>? addresses,
    String? message,
  }) => AddressState(
    status: status ?? this.status,
    addresses: addresses ?? this.addresses,
    message: message,
  );

  @override
  List<Object?> get props => [status, addresses, message];
}
