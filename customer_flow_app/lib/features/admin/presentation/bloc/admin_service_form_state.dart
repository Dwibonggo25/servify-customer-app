import 'package:equatable/equatable.dart';

import '../../../services/domain/entities/service_category.dart';

enum AdminServiceFormStatus {
  initial,
  loading,
  ready,
  saving,
  success,
  failure,
}

final class AdminServiceFormState extends Equatable {
  const AdminServiceFormState({
    this.status = AdminServiceFormStatus.initial,
    this.categories = const [],
    this.message,
  });

  final AdminServiceFormStatus status;
  final List<ServiceCategory> categories;
  final String? message;

  bool get isLoading =>
      status == AdminServiceFormStatus.initial ||
      status == AdminServiceFormStatus.loading;
  bool get isSaving => status == AdminServiceFormStatus.saving;

  AdminServiceFormState copyWith({
    AdminServiceFormStatus? status,
    List<ServiceCategory>? categories,
    String? message,
  }) => AdminServiceFormState(
    status: status ?? this.status,
    categories: categories ?? this.categories,
    message: message,
  );

  @override
  List<Object?> get props => [status, categories, message];
}
