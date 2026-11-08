import 'package:equatable/equatable.dart';

import '../../domain/entities/service_item.dart';

enum ServiceCatalogStatus { initial, loading, success, failure }

final class ServiceCatalogState extends Equatable {
  const ServiceCatalogState({
    this.status = ServiceCatalogStatus.initial,
    this.services = const [],
    this.message,
  });

  final ServiceCatalogStatus status;
  final List<ServiceItem> services;
  final String? message;

  bool get isLoading =>
      status == ServiceCatalogStatus.initial ||
      status == ServiceCatalogStatus.loading;

  @override
  List<Object?> get props => [status, services, message];
}
