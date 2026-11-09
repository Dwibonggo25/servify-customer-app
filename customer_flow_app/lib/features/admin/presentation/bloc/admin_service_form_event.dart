import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../../services/domain/entities/service_draft.dart';

sealed class AdminServiceFormEvent extends Equatable {
  const AdminServiceFormEvent();

  @override
  List<Object?> get props => const [];
}

final class AdminServiceFormStarted extends AdminServiceFormEvent {
  const AdminServiceFormStarted();
}

final class AdminServiceSubmitted extends AdminServiceFormEvent {
  const AdminServiceSubmitted({
    required this.serviceId,
    required this.draft,
    this.imageBytes,
    this.imageExtension,
  });

  final String? serviceId;
  final ServiceDraft draft;
  final Uint8List? imageBytes;
  final String? imageExtension;

  @override
  List<Object?> get props => [serviceId, draft, imageBytes, imageExtension];
}
