import 'package:hive_ce/hive.dart';

import '../../../../libraries/core/constants/app_constants.dart';
import '../../domain/repositories/onboarding_repository.dart';

final class HiveOnboardingRepository implements OnboardingRepository {
  const HiveOnboardingRepository(this._box);

  final Box<dynamic> _box;

  @override
  bool get isCompleted =>
      _box.get(AppConstants.onboardingKey, defaultValue: false) as bool;

  @override
  Future<void> complete() => _box.put(AppConstants.onboardingKey, true);
}
