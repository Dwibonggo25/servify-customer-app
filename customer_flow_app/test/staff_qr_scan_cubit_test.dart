import 'package:customer_flow_app/features/qr_verification/domain/entities/booking_qr_code.dart';
import 'package:customer_flow_app/features/qr_verification/domain/entities/staff_location.dart';
import 'package:customer_flow_app/features/qr_verification/domain/repositories/booking_qr_repository.dart';
import 'package:customer_flow_app/features/qr_verification/domain/repositories/location_repository.dart';
import 'package:customer_flow_app/features/qr_verification/presentation/cubit/staff_qr_scan_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('captures location before sending QR verification', () async {
    const location = StaffLocation(
      latitude: -6.2,
      longitude: 106.8,
      accuracy: 8,
    );
    final qrRepository = _FakeBookingQrRepository();
    final cubit = StaffQrScanCubit(
      qrRepository: qrRepository,
      locationRepository: const _FakeLocationRepository(location),
      bookingId: 'booking-1',
    );

    await cubit.verify('secure-token');

    expect(cubit.state.status, StaffQrScanStatus.success);
    expect(qrRepository.receivedBookingId, 'booking-1');
    expect(qrRepository.receivedToken, 'secure-token');
    expect(qrRepository.receivedLocation, location);
    await cubit.close();
  });
}

final class _FakeLocationRepository implements LocationRepository {
  const _FakeLocationRepository(this.location);

  final StaffLocation location;

  @override
  Future<StaffLocation> getCurrentLocation() async => location;
}

final class _FakeBookingQrRepository implements BookingQrRepository {
  String? receivedBookingId;
  String? receivedToken;
  StaffLocation? receivedLocation;

  @override
  Future<BookingQrCode> getOrCreateQr({
    required String bookingId,
    required BookingQrPurpose purpose,
  }) => throw UnimplementedError();

  @override
  Future<QrVerificationResult> verifyQr({
    required String bookingId,
    required String token,
    required StaffLocation location,
  }) async {
    receivedBookingId = bookingId;
    receivedToken = token;
    receivedLocation = location;
    return const QrVerificationResult(
      success: true,
      message: 'Berhasil',
      bookingStatus: 'in_progress',
    );
  }
}
