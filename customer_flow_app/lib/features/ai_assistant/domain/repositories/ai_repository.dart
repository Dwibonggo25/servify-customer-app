abstract interface class AiRepository {
  Future<String> generateResponse({required String prompt});
}
