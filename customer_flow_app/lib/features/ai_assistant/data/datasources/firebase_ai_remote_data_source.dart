import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';

import 'ai_remote_data_source.dart';

final class FirebaseAiRemoteDataSource implements AiRemoteDataSource {
  FirebaseAiRemoteDataSource({
    FirebaseAI? client,
    String modelName = defaultModelName,
    Duration requestTimeout = const Duration(seconds: 30),
  }) : _requestTimeout = requestTimeout,
       _model = (client ?? FirebaseAI.googleAI()).generativeModel(
         model: modelName,
         systemInstruction: Content.system(_systemInstruction),
       );

  static const defaultModelName = 'gemini-3.8-flash';

  static const _systemInstruction = '''
You are Servify's customer assistant. Help customers understand which service
category may fit their needs. Reply in the same language as the customer, keep
the answer concise, and never invent prices, availability, booking status, or
service details that were not provided in the prompt.
''';

  final GenerativeModel _model;
  final Duration _requestTimeout;

  @override
  Future<String> generateResponse({required String prompt}) async {
    final normalizedPrompt = prompt.trim();
    if (normalizedPrompt.isEmpty) {
      throw ArgumentError.value(prompt, 'prompt', 'Prompt cannot be empty.');
    }

    final response = await _model
        .generateContent([Content.text(normalizedPrompt)])
        .timeout(
          _requestTimeout,
          onTimeout: () => throw TimeoutException(
            'Firebase AI did not respond within the allowed time.',
            _requestTimeout,
          ),
        );
    final text = response.text?.trim();
    if (text == null || text.isEmpty) {
      throw const AiEmptyResponseException();
    }
    return text;
  }
}

final class AiEmptyResponseException implements Exception {
  const AiEmptyResponseException();

  @override
  String toString() => 'Firebase AI returned an empty text response.';
}
