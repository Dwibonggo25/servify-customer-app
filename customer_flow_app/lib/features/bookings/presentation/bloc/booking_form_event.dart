import 'package:equatable/equatable.dart';

import '../../domain/entities/booking_draft.dart';

sealed class BookingFormEvent extends Equatable {
  const BookingFormEvent();

  @override
  List<Object?> get props => const [];
}

final class BookingSubmitted extends BookingFormEvent {
  const BookingSubmitted(this.draft);

  final BookingDraft draft;

  @override
  List<Object?> get props => [draft];
}
