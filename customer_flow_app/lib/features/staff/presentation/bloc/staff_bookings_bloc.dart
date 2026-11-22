import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bookings/domain/entities/booking_record.dart';
import '../../../bookings/domain/repositories/booking_repository.dart';
import 'staff_bookings_event.dart';
import 'staff_bookings_state.dart';

final class StaffBookingsBloc
    extends Bloc<StaffBookingsEvent, StaffBookingsState> {
  StaffBookingsBloc(this._repository) : super(const StaffBookingsState()) {
    on<StaffBookingsRequested>(_onRequested);
    on<StaffBookingsRealtimeStarted>(_onRealtimeStarted);
    on<StaffBookingsRealtimeUpdated>(_onRealtimeUpdated);
    on<StaffBookingsRealtimeFailed>(_onRealtimeFailed);
  }

  final BookingRepository _repository;
  StreamSubscription<List<BookingRecord>>? _realtimeSubscription;

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
          realtimeConnected: state.realtimeConnected,
          realtimeFailed: state.realtimeFailed,
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
        state.copyWith(status: StaffBookingsStatus.failure, refreshing: false),
      );
    }
  }

  Future<void> _onRealtimeStarted(
    StaffBookingsRealtimeStarted event,
    Emitter<StaffBookingsState> emit,
  ) async {
    if (state.bookings.isEmpty) {
      emit(state.copyWith(status: StaffBookingsStatus.loading));
    }

    await _realtimeSubscription?.cancel();
    _realtimeSubscription = _repository.watchStaffBookings().listen(
      (bookings) {
        if (!isClosed) add(StaffBookingsRealtimeUpdated(bookings));
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!isClosed) add(StaffBookingsRealtimeFailed(error, stackTrace));
      },
    );
  }

  void _onRealtimeUpdated(
    StaffBookingsRealtimeUpdated event,
    Emitter<StaffBookingsState> emit,
  ) {
    emit(
      StaffBookingsState(
        status: StaffBookingsStatus.success,
        bookings: event.bookings,
        realtimeConnected: true,
      ),
    );
  }

  void _onRealtimeFailed(
    StaffBookingsRealtimeFailed event,
    Emitter<StaffBookingsState> emit,
  ) {
    developer.log(
      'Koneksi realtime pesanan staf terputus',
      name: 'StaffBookingsBloc',
      error: event.error,
      stackTrace: event.stackTrace,
    );
    emit(
      state.copyWith(
        status: state.bookings.isEmpty
            ? StaffBookingsStatus.failure
            : StaffBookingsStatus.success,
        realtimeConnected: false,
        realtimeFailed: true,
        refreshing: false,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _realtimeSubscription?.cancel();
    return super.close();
  }
}
