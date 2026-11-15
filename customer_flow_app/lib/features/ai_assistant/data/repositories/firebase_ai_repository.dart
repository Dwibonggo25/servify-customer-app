import '../../domain/repositories/ai_repository.dart';
import '../datasources/ai_remote_data_source.dart';

final class FirebaseAiRepository implements AiRepository {
  const FirebaseAiRepository(this._remoteDataSource);

  final AiRemoteDataSource _remoteDataSource;

  @override
  Future<String> generateResponse({required String prompt}) {
    return _remoteDataSource.generateResponse(prompt: prompt);
  }
}
