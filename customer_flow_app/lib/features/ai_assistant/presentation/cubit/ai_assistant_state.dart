import 'package:equatable/equatable.dart';

enum AiAssistantStatus { initial, loading, success, failure }

final class AiAssistantState extends Equatable {
  const AiAssistantState({
    this.status = AiAssistantStatus.initial,
    this.response,
    this.message,
  });

  final AiAssistantStatus status;
  final String? response;
  final String? message;

  bool get isLoading => status == AiAssistantStatus.loading;

  @override
  List<Object?> get props => [status, response, message];
}
