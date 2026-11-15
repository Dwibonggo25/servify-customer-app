import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../libraries/core/localization/language_controller.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../domain/repositories/ai_repository.dart';
import 'ai_assistant_state.dart';

final class AiAssistantCubit extends Cubit<AiAssistantState> {
  AiAssistantCubit(this._repository) : super(const AiAssistantState());

  final AiRepository _repository;

  Future<void> ask(String prompt) async {
    final normalizedPrompt = prompt.trim();
    if (normalizedPrompt.isEmpty) {
      emit(
        AiAssistantState(
          status: AiAssistantStatus.failure,
          message: LanguageController.instance.translate(
            LanguageKeys.aiEmptyPrompt,
          ),
        ),
      );
      return;
    }

    emit(const AiAssistantState(status: AiAssistantStatus.loading));
    log('Sending request to Firebase AI.', name: 'AiAssistantCubit');
    try {
      final response = await _repository.generateResponse(
        prompt: normalizedPrompt,
      );
      log('Firebase AI response received.', name: 'AiAssistantCubit');
      emit(
        AiAssistantState(status: AiAssistantStatus.success, response: response),
      );
    } on TimeoutException catch (error, stackTrace) {
      log(
        'Firebase AI request timed out.',
        name: 'AiAssistantCubit',
        error: error,
        stackTrace: stackTrace,
      );
      emit(
        AiAssistantState(
          status: AiAssistantStatus.failure,
          message: LanguageController.instance.translate(
            LanguageKeys.aiRequestTimedOut,
          ),
        ),
      );
    } catch (error, stackTrace) {
      log(
        'Firebase AI request failed.',
        name: 'AiAssistantCubit',
        error: error,
        stackTrace: stackTrace,
      );
      emit(
        AiAssistantState(
          status: AiAssistantStatus.failure,
          message: LanguageController.instance.translate(
            LanguageKeys.aiRequestFailed,
          ),
        ),
      );
    }
  }
}
