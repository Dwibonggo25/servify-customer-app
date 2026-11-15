abstract interface class AiRemoteDataSource {
  Future<String> generateResponse({required String prompt});
}
