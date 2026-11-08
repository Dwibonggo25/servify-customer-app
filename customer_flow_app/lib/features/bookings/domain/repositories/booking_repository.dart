import '../entities/booking_draft.dart';
import '../entities/booking_record.dart';

abstract interface class BookingRepository {
  Future<BookingRecord> createBooking(BookingDraft draft);

  Future<List<BookingRecord>> getCustomerBookings();

  Future<BookingRecord?> getCustomerBooking(String id);

  Future<List<BookingRecord>> getStaffBookings();

  Future<BookingRecord?> getStaffBooking(String id);

  Future<void> respondToBooking(String id, {required bool accept});

  Future<void> updateProgress(String id, String status);
}
