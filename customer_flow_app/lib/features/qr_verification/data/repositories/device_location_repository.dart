import 'package:geolocator/geolocator.dart';

import '../../domain/entities/staff_location.dart';
import '../../domain/repositories/location_repository.dart';

final class DeviceLocationRepository implements LocationRepository {
  const DeviceLocationRepository();

  @override
  Future<StaffLocation> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError(
        'Layanan lokasi tidak aktif. Aktifkan GPS lalu coba kembali.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw StateError('Izin lokasi diperlukan untuk verifikasi QR.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw StateError(
        'Izin lokasi ditolak permanen. Aktifkan melalui pengaturan perangkat.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return StaffLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
    );
  }
}
