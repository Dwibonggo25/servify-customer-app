import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/work_proof.dart';
import '../../domain/repositories/work_proof_repository.dart';
import 'work_proof_state.dart';

final class WorkProofCubit extends Cubit<WorkProofState> {
  WorkProofCubit({
    required WorkProofRepository repository,
    required String bookingId,
  }) : _repository = repository,
       _bookingId = bookingId,
       super(const WorkProofState());

  final WorkProofRepository _repository;
  final String _bookingId;

  Future<void> load() async {
    emit(state.copyWith(status: WorkProofStatus.loading));
    try {
      final proofs = await _repository.getForBooking(_bookingId);
      emit(WorkProofState(status: WorkProofStatus.ready, proofs: proofs));
    } catch (error, stackTrace) {
      developer.log(
        'Bukti pekerjaan gagal dimuat',
        name: 'WorkProofCubit',
        error: error,
        stackTrace: stackTrace,
      );
      emit(
        state.copyWith(
          status: WorkProofStatus.failure,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> upload({
    required WorkProofType type,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    if (state.isBusy) return;
    emit(state.copyWith(status: WorkProofStatus.uploading));
    try {
      final proof = await _repository.upload(
        bookingId: _bookingId,
        type: type,
        bytes: bytes,
        fileExtension: fileExtension,
      );
      emit(
        WorkProofState(
          status: WorkProofStatus.ready,
          proofs: [...state.proofs, proof],
          message: 'uploaded',
        ),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Bukti pekerjaan gagal diunggah',
        name: 'WorkProofCubit',
        error: error,
        stackTrace: stackTrace,
      );
      emit(
        state.copyWith(
          status: WorkProofStatus.failure,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> delete(WorkProof proof) async {
    if (state.isBusy) return;
    emit(state.copyWith(status: WorkProofStatus.deleting));
    try {
      await _repository.delete(proof);
      emit(
        WorkProofState(
          status: WorkProofStatus.ready,
          proofs: state.proofs
              .where((item) => item.id != proof.id)
              .toList(growable: false),
          message: 'deleted',
        ),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Bukti pekerjaan gagal dihapus',
        name: 'WorkProofCubit',
        error: error,
        stackTrace: stackTrace,
      );
      emit(
        state.copyWith(
          status: WorkProofStatus.failure,
          message: error.toString(),
        ),
      );
    }
  }

  void clearMessage() => emit(state.copyWith(message: null));
}
