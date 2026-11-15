import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/booking_record.dart';
import '../../domain/entities/booking_review.dart';
import '../../domain/repositories/booking_repository.dart';
import 'booking_detail_event.dart';
import 'booking_detail_state.dart';

final class BookingDetailBloc
    extends Bloc<BookingDetailEvent, BookingDetailState> {
  BookingDetailBloc({
    required BookingRepository repository,
    required String bookingId,
    required bool staffMode,
  }) : _repository = repository,
       _bookingId = bookingId,
       _staffMode = staffMode,
       super(const BookingDetailState()) {
    on<BookingDetailRequested>(_onRequested);
    on<BookingResponseSubmitted>(_onResponseSubmitted);
    on<BookingProgressSubmitted>(_onProgressSubmitted);
    on<BookingCancellationSubmitted>(_onCancellationSubmitted);
    on<BookingReviewSubmitted>(_onReviewSubmitted);
    on<BookingRealtimeUpdated>(_onRealtimeUpdated);
    on<BookingRealtimeDisconnected>(_onRealtimeDisconnected);
  }

  final BookingRepository _repository;
  final String _bookingId;
  final bool _staffMode;
  StreamSubscription<BookingRecord>? _trackingSubscription;

  Future<BookingRecord?> _load() => _staffMode
      ? _repository.getStaffBooking(_bookingId)
      : _repository.getCustomerBooking(_bookingId);

  Future<BookingReview?> _loadReview(BookingRecord? booking) {
    if (_staffMode || booking?.status != 'completed') {
      return Future.value();
    }
    return _repository.getBookingReview(_bookingId);
  }

  Future<void> _onRequested(
    BookingDetailRequested event,
    Emitter<BookingDetailState> emit,
  ) async {
    emit(state.copyWith(status: BookingDetailStatus.loading));
    try {
      final booking = await _load();
      final review = await _loadReview(booking);
      emit(
        BookingDetailState(
          status: BookingDetailStatus.success,
          booking: booking,
          review: review,
        ),
      );
      if (!_staffMode) await _startRealtimeTracking();
    } catch (error, stackTrace) {
      _log(error, stackTrace);
      emit(
        state.copyWith(
          status: BookingDetailStatus.failure,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> _onResponseSubmitted(
    BookingResponseSubmitted event,
    Emitter<BookingDetailState> emit,
  ) async {
    emit(state.copyWith(status: BookingDetailStatus.submitting));
    try {
      await _repository.respondToBooking(_bookingId, accept: event.accept);
      if (!event.accept) {
        emit(
          state.copyWith(
            status: BookingDetailStatus.actionSuccess,
            feedback: BookingDetailFeedback.bookingRejected,
            shouldPop: true,
            realtimeConnected: state.realtimeConnected,
            realtimeFailed: state.realtimeFailed,
          ),
        );
        return;
      }
      final booking = await _load();
      emit(
        BookingDetailState(
          status: BookingDetailStatus.actionSuccess,
          booking: booking,
          feedback: BookingDetailFeedback.bookingAccepted,
          realtimeConnected: state.realtimeConnected,
          realtimeFailed: state.realtimeFailed,
        ),
      );
    } catch (error, stackTrace) {
      _actionFailure(error, stackTrace, emit);
    }
  }

  Future<void> _onProgressSubmitted(
    BookingProgressSubmitted event,
    Emitter<BookingDetailState> emit,
  ) async {
    emit(state.copyWith(status: BookingDetailStatus.submitting));
    try {
      await _repository.updateProgress(_bookingId, event.status);
      final booking = await _load();
      emit(
        BookingDetailState(
          status: BookingDetailStatus.actionSuccess,
          booking: booking,
          feedback: BookingDetailFeedback.progressUpdated,
          realtimeConnected: state.realtimeConnected,
          realtimeFailed: state.realtimeFailed,
        ),
      );
    } catch (error, stackTrace) {
      _actionFailure(error, stackTrace, emit);
    }
  }

  Future<void> _onCancellationSubmitted(
    BookingCancellationSubmitted event,
    Emitter<BookingDetailState> emit,
  ) async {
    emit(state.copyWith(status: BookingDetailStatus.submitting));
    try {
      await _repository.cancelBooking(_bookingId);
      final booking = await _load();
      emit(
        BookingDetailState(
          status: BookingDetailStatus.actionSuccess,
          booking: booking,
          feedback: BookingDetailFeedback.bookingCancelled,
          realtimeConnected: state.realtimeConnected,
          realtimeFailed: state.realtimeFailed,
        ),
      );
    } catch (error, stackTrace) {
      _actionFailure(error, stackTrace, emit);
    }
  }

  Future<void> _onReviewSubmitted(
    BookingReviewSubmitted event,
    Emitter<BookingDetailState> emit,
  ) async {
    final booking = state.booking;
    if (_staffMode || booking?.status != 'completed') return;

    emit(state.copyWith(status: BookingDetailStatus.submitting));
    try {
      final review = await _repository.submitBookingReview(
        bookingId: _bookingId,
        rating: event.rating,
        comment: event.comment,
      );
      emit(
        state.copyWith(
          status: BookingDetailStatus.actionSuccess,
          review: review,
          feedback: BookingDetailFeedback.reviewSaved,
        ),
      );
    } catch (error, stackTrace) {
      _actionFailure(error, stackTrace, emit);
    }
  }

  void _actionFailure(
    Object error,
    StackTrace stackTrace,
    Emitter<BookingDetailState> emit,
  ) {
    _log(error, stackTrace);
    emit(
      state.copyWith(
        status: BookingDetailStatus.failure,
        message: error.toString(),
      ),
    );
  }

  Future<void> _startRealtimeTracking() async {
    await _trackingSubscription?.cancel();
    _trackingSubscription = _repository
        .watchCustomerBooking(_bookingId)
        .listen(
          (booking) => add(BookingRealtimeUpdated(booking)),
          onError: (Object error, StackTrace stackTrace) {
            _log(error, stackTrace);
            add(BookingRealtimeDisconnected(error));
          },
        );
  }

  Future<void> _onRealtimeUpdated(
    BookingRealtimeUpdated event,
    Emitter<BookingDetailState> emit,
  ) async {
    final review = event.booking.status == 'completed'
        ? await _repository.getBookingReview(_bookingId)
        : state.review;
    emit(
      BookingDetailState(
        status: BookingDetailStatus.success,
        booking: event.booking,
        review: review,
        realtimeConnected: true,
        realtimeFailed: false,
      ),
    );
  }

  void _onRealtimeDisconnected(
    BookingRealtimeDisconnected _,
    Emitter<BookingDetailState> emit,
  ) {
    emit(
      state.copyWith(
        status: BookingDetailStatus.success,
        realtimeConnected: false,
        realtimeFailed: true,
      ),
    );
  }

  void _log(Object error, StackTrace stackTrace) {
    developer.log(
      'Operasi detail pesanan gagal',
      name: 'BookingDetailBloc',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  Future<void> close() async {
    await _trackingSubscription?.cancel();
    return super.close();
  }
}
