import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/booking_repository.dart';
import 'booking_history_state.dart';

final class BookingHistoryCubit extends Cubit<BookingHistoryState> {
  BookingHistoryCubit(this._repository) : super(const BookingHistoryState());

  final BookingRepository _repository;

  Future<void> load({bool refresh = false}) async {
    if (refresh && state.bookings.isNotEmpty) {
      emit(state.copyWith(refreshing: true));
    } else {
      emit(state.copyWith(status: BookingHistoryStatus.loading));
    }

    try {
      final bookings = await _repository.getCustomerBookings();
      emit(
        state.copyWith(
          status: BookingHistoryStatus.success,
          bookings: bookings,
          refreshing: false,
        ),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Daftar pesanan customer gagal dimuat',
        name: 'BookingHistoryCubit',
        error: error,
        stackTrace: stackTrace,
      );
      emit(
        state.copyWith(status: BookingHistoryStatus.failure, refreshing: false),
      );
    }
  }

  void selectFilter(BookingHistoryFilter filter) {
    if (filter == state.filter) return;
    emit(state.copyWith(filter: filter));
  }
}
