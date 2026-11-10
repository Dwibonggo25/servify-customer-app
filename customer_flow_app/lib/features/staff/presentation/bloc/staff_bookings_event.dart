import 'package:equatable/equatable.dart';

sealed class StaffBookingsEvent extends Equatable {
  const StaffBookingsEvent();

  @override
  List<Object?> get props => const [];
}

final class StaffBookingsRequested extends StaffBookingsEvent {
  const StaffBookingsRequested({this.refresh = false});

  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}
