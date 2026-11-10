import '../entities/staff_location.dart';

abstract interface class LocationRepository {
  Future<StaffLocation> getCurrentLocation();
}
