import '../entities/booking_qr_code.dart';
import '../entities/staff_location.dart';

abstract interface class BookingQrRepository {
  Future<BookingQrCode> getOrCreateQr({
    required String bookingId,
    required BookingQrPurpose purpose,
  });

  Future<QrVerificationResult> verifyQr({
    required String bookingId,
    required String token,
    required StaffLocation location,
  });
}
