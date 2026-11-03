import 'package:equatable/equatable.dart';

import '../../domain/entities/service_category.dart';

enum ServiceCategoryStatus { initial, loading, success, failure }

final class ServiceCategoryState extends Equatable {
  const ServiceCategoryState({
    this.status = ServiceCategoryStatus.initial,
    this.categories = const [],
    this.message,
  });

  final ServiceCategoryStatus status;
  final List<ServiceCategory> categories;
  final String? message;

  bool get isLoading =>
      status == ServiceCategoryStatus.initial ||
      status == ServiceCategoryStatus.loading;

  @override
  List<Object?> get props => [status, categories, message];
}
