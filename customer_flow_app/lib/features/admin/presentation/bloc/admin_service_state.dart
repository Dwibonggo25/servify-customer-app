import 'package:equatable/equatable.dart';

import '../../../services/domain/entities/service_item.dart';

enum AdminServiceStatus {
  initial,
  loading,
  success,
  deleting,
  deleteSuccess,
  failure,
}

final class AdminServiceState extends Equatable {
  const AdminServiceState({
    this.status = AdminServiceStatus.initial,
    this.services = const [],
    this.message,
  });

  final AdminServiceStatus status;
  final List<ServiceItem> services;
  final String? message;

  bool get isLoading =>
      status == AdminServiceStatus.initial ||
      (status == AdminServiceStatus.loading && services.isEmpty);

  AdminServiceState copyWith({
    AdminServiceStatus? status,
    List<ServiceItem>? services,
    String? message,
  }) => AdminServiceState(
    status: status ?? this.status,
    services: services ?? this.services,
    message: message,
  );

  @override
  List<Object?> get props => [status, services, message];
}
