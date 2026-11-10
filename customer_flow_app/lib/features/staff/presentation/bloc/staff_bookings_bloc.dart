import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bookings/domain/repositories/booking_repository.dart';
import 'staff_bookings_event.dart';
import 'staff_bookings_state.dart';

final class StaffBookingsBloc
    extends Bloc<StaffBookingsEvent, StaffBookingsState> {
  StaffBookingsBloc(this._repository) : super(const StaffBookingsState()) {
    on<StaffBookingsRequested>(_onRequested);
  }

  final BookingRepository _repository;

  Future<void> _onRequested(
    StaffBookingsRequested event,
    Emitter<StaffBookingsState> emit,
  ) async {
    if (event.refresh && state.bookings.isNotEmpty) {
      emit(state.copyWith(refreshing: true));
    } else {
      emit(
        state.copyWith(status: StaffBookingsStatus.loading, refreshing: false),
      );
    }

    try {
      final bookings = await _repository.getStaffBookings();
      emit(
        StaffBookingsState(
          status: StaffBookingsStatus.success,
          bookings: bookings,
        ),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Daftar pesanan staff gagal dimuat',
        name: 'StaffBookingsBloc',
        error: error,
        stackTrace: stackTrace,
      );
      emit(
        state.copyWith(
          status: StaffBookingsStatus.failure,
          message: 'Pesanan gagal dimuat. Periksa koneksi lalu coba kembali.',
          refreshing: false,
        ),
      );
    }
  }
}
