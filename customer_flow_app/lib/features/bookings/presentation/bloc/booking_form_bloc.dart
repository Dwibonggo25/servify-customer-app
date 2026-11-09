import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/booking_repository.dart';
import 'booking_form_event.dart';
import 'booking_form_state.dart';

final class BookingFormBloc extends Bloc<BookingFormEvent, BookingFormState> {
  BookingFormBloc(this._repository) : super(const BookingFormState()) {
    on<BookingSubmitted>(_onSubmitted);
  }

  final BookingRepository _repository;

  Future<void> _onSubmitted(
    BookingSubmitted event,
    Emitter<BookingFormState> emit,
  ) async {
    emit(const BookingFormState(status: BookingFormStatus.submitting));
    try {
      final booking = await _repository.createBooking(event.draft);
      emit(
        BookingFormState(status: BookingFormStatus.success, booking: booking),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Gagal membuat pesanan',
        name: 'BookingFormBloc',
        error: error,
        stackTrace: stackTrace,
      );
      emit(
        BookingFormState(
          status: BookingFormStatus.failure,
          message: 'Pesanan gagal dibuat: $error',
        ),
      );
    }
  }
}
