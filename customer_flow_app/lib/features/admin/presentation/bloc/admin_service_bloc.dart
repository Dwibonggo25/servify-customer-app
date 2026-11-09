import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../services/domain/repositories/service_repository.dart';
import 'admin_service_event.dart';
import 'admin_service_state.dart';

final class AdminServiceBloc
    extends Bloc<AdminServiceEvent, AdminServiceState> {
  AdminServiceBloc(this._repository) : super(const AdminServiceState()) {
    on<AdminServicesRequested>(_onServicesRequested);
    on<AdminServiceDeleteRequested>(_onDeleteRequested);
  }

  final ServiceRepository _repository;

  Future<void> _onServicesRequested(
    AdminServicesRequested event,
    Emitter<AdminServiceState> emit,
  ) async {
    emit(state.copyWith(status: AdminServiceStatus.loading));
    try {
      final services = await _repository.getAllServicesForAdmin();
      emit(
        AdminServiceState(
          status: AdminServiceStatus.success,
          services: services,
        ),
      );
      event.completer?.complete();
    } catch (error, stackTrace) {
      emit(
        state.copyWith(
          status: AdminServiceStatus.failure,
          message: 'Gagal memuat layanan: $error',
        ),
      );
      event.completer?.completeError(error, stackTrace);
    }
  }

  Future<void> _onDeleteRequested(
    AdminServiceDeleteRequested event,
    Emitter<AdminServiceState> emit,
  ) async {
    emit(state.copyWith(status: AdminServiceStatus.deleting));
    try {
      await _repository.deleteService(event.serviceId);
      final services = await _repository.getAllServicesForAdmin();
      emit(
        AdminServiceState(
          status: AdminServiceStatus.deleteSuccess,
          services: services,
          message: 'Layanan berhasil dihapus/diarsipkan.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AdminServiceStatus.failure,
          message: 'Gagal menghapus layanan: $error',
        ),
      );
    }
  }
}
