import 'package:equatable/equatable.dart';

import '../../domain/entities/booking_record.dart';

enum BookingHistoryStatus { initial, loading, success, failure }

enum BookingHistoryFilter { all, ongoing, completed }

final class BookingHistoryState extends Equatable {
  const BookingHistoryState({
    this.status = BookingHistoryStatus.initial,
    this.filter = BookingHistoryFilter.all,
    this.bookings = const [],
    this.refreshing = false,
  });

  final BookingHistoryStatus status;
  final BookingHistoryFilter filter;
  final List<BookingRecord> bookings;
  final bool refreshing;

  bool get isLoading =>
      status == BookingHistoryStatus.initial ||
      status == BookingHistoryStatus.loading;

  List<BookingRecord> get visibleBookings => bookings
      .where((booking) {
        return switch (filter) {
          BookingHistoryFilter.ongoing => !booking.isFinished,
          BookingHistoryFilter.completed => booking.status == 'completed',
          BookingHistoryFilter.all => true,
        };
      })
      .toList(growable: false);

  BookingHistoryState copyWith({
    BookingHistoryStatus? status,
    BookingHistoryFilter? filter,
    List<BookingRecord>? bookings,
    bool? refreshing,
  }) => BookingHistoryState(
    status: status ?? this.status,
    filter: filter ?? this.filter,
    bookings: bookings ?? this.bookings,
    refreshing: refreshing ?? this.refreshing,
  );

  @override
  List<Object?> get props => [status, filter, bookings, refreshing];
}
