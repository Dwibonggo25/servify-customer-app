import 'dart:async';

import 'package:equatable/equatable.dart';

sealed class AdminServiceEvent extends Equatable {
  const AdminServiceEvent();

  @override
  List<Object?> get props => const [];
}

final class AdminServicesRequested extends AdminServiceEvent {
  const AdminServicesRequested({this.completer});

  final Completer<void>? completer;
}

final class AdminServiceDeleteRequested extends AdminServiceEvent {
  const AdminServiceDeleteRequested(this.serviceId);

  final String serviceId;

  @override
  List<Object?> get props => [serviceId];
}
