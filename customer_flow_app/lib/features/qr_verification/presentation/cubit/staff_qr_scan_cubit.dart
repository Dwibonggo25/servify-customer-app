import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/booking_qr_repository.dart';
import '../../domain/repositories/location_repository.dart';

enum StaffQrScanStatus { ready, locating, verifying, success, failure }

final class StaffQrScanState extends Equatable {
  const StaffQrScanState({this.status = StaffQrScanStatus.ready, this.message});

  final StaffQrScanStatus status;
  final String? message;

  bool get isProcessing =>
      status == StaffQrScanStatus.locating ||
      status == StaffQrScanStatus.verifying;

  @override
  List<Object?> get props => [status, message];
}

final class StaffQrScanCubit extends Cubit<StaffQrScanState> {
  StaffQrScanCubit({
    required BookingQrRepository qrRepository,
    required LocationRepository locationRepository,
    required String bookingId,
  }) : _qrRepository = qrRepository,
       _locationRepository = locationRepository,
       _bookingId = bookingId,
       super(const StaffQrScanState());

  final BookingQrRepository _qrRepository;
  final LocationRepository _locationRepository;
  final String _bookingId;

  Future<void> verify(String token) async {
    if (state.isProcessing || token.trim().isEmpty) return;
    try {
      emit(
        const StaffQrScanState(
          status: StaffQrScanStatus.locating,
          message: 'Mengambil lokasi staf...',
        ),
      );
      final location = await _locationRepository.getCurrentLocation();
      emit(
        const StaffQrScanState(
          status: StaffQrScanStatus.verifying,
          message: 'Memverifikasi QR dan lokasi...',
        ),
      );
      final result = await _qrRepository.verifyQr(
        bookingId: _bookingId,
        token: token.trim(),
        location: location,
      );
      emit(
        StaffQrScanState(
          status: result.success
              ? StaffQrScanStatus.success
              : StaffQrScanStatus.failure,
          message: result.message,
        ),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Verifikasi QR gagal',
        name: 'StaffQrScanCubit',
        error: error,
        stackTrace: stackTrace,
      );
      emit(
        StaffQrScanState(
          status: StaffQrScanStatus.failure,
          message: 'Verifikasi gagal: $error',
        ),
      );
    }
  }

  void retry() => emit(const StaffQrScanState());
}
