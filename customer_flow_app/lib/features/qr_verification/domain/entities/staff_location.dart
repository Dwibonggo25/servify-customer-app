import 'package:equatable/equatable.dart';

final class StaffLocation extends Equatable {
  const StaffLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });

  final double latitude;
  final double longitude;
  final double accuracy;

  @override
  List<Object?> get props => [latitude, longitude, accuracy];
}
