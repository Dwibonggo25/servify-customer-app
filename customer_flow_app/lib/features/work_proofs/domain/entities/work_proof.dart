import 'package:equatable/equatable.dart';

enum WorkProofType {
  before('before'),
  after('after');

  const WorkProofType(this.value);

  final String value;

  static WorkProofType fromValue(String value) => switch (value) {
    'after' => WorkProofType.after,
    _ => WorkProofType.before,
  };
}

final class WorkProof extends Equatable {
  const WorkProof({
    required this.id,
    required this.bookingId,
    required this.staffId,
    required this.type,
    required this.storagePath,
    required this.imageUrl,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final String staffId;
  final WorkProofType type;
  final String storagePath;
  final String imageUrl;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    bookingId,
    staffId,
    type,
    storagePath,
    imageUrl,
    createdAt,
  ];
}
