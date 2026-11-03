abstract interface class OnboardingRepository {
  bool get isCompleted;

  Future<void> complete();
}
