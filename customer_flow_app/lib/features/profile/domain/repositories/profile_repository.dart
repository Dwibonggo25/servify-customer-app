import '../entities/customer_profile.dart';

abstract interface class ProfileRepository {
  Future<CustomerProfile> getProfile();

  Future<CustomerProfile> updateProfile({
    required String fullName,
    required String phone,
  });
}
