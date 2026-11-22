import 'package:equatable/equatable.dart';

import '../../domain/entities/work_proof.dart';

enum WorkProofStatus { initial, loading, ready, uploading, deleting, failure }

final class WorkProofState extends Equatable {
  const WorkProofState({
    this.status = WorkProofStatus.initial,
    this.proofs = const [],
    this.message,
  });

  final WorkProofStatus status;
  final List<WorkProof> proofs;
  final String? message;

  bool get isInitialLoading =>
      (status == WorkProofStatus.initial ||
          status == WorkProofStatus.loading) &&
      proofs.isEmpty;
  bool get isBusy =>
      status == WorkProofStatus.uploading || status == WorkProofStatus.deleting;
  List<WorkProof> get before => proofs
      .where((proof) => proof.type == WorkProofType.before)
      .toList(growable: false);
  List<WorkProof> get after => proofs
      .where((proof) => proof.type == WorkProofType.after)
      .toList(growable: false);

  WorkProofState copyWith({
    WorkProofStatus? status,
    List<WorkProof>? proofs,
    String? message,
  }) => WorkProofState(
    status: status ?? this.status,
    proofs: proofs ?? this.proofs,
    message: message,
  );

  @override
  List<Object?> get props => [status, proofs, message];
}
