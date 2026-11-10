import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/booking_qr_code.dart';
import '../../domain/repositories/booking_qr_repository.dart';

enum CustomerQrStatus { initial, loading, success, failure }

final class CustomerQrState extends Equatable {
  const CustomerQrState({
    this.status = CustomerQrStatus.initial,
    this.qrCode,
    this.message,
  });

  final CustomerQrStatus status;
  final BookingQrCode? qrCode;
  final String? message;

  @override
  List<Object?> get props => [status, qrCode, message];
}

final class CustomerQrCubit extends Cubit<CustomerQrState> {
  CustomerQrCubit(this._repository) : super(const CustomerQrState());

  final BookingQrRepository _repository;

  Future<void> load({
    required String bookingId,
    required BookingQrPurpose purpose,
  }) async {
    emit(const CustomerQrState(status: CustomerQrStatus.loading));
    try {
      final qrCode = await _repository.getOrCreateQr(
        bookingId: bookingId,
        purpose: purpose,
      );
      emit(CustomerQrState(status: CustomerQrStatus.success, qrCode: qrCode));
    } catch (error) {
      emit(
        CustomerQrState(
          status: CustomerQrStatus.failure,
          message: 'QR gagal dibuat: $error',
        ),
      );
    }
  }
}
