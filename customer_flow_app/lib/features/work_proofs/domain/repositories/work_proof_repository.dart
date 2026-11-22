import 'dart:typed_data';

import '../entities/work_proof.dart';

abstract interface class WorkProofRepository {
  Future<List<WorkProof>> getForBooking(String bookingId);

  Future<WorkProof> upload({
    required String bookingId,
    required WorkProofType type,
    required Uint8List bytes,
    required String fileExtension,
  });

  Future<void> delete(WorkProof proof);
}
