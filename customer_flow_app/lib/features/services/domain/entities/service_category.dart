import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

final class ServiceCategory extends Equatable {
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.iconKey,
    required this.colorValue,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String slug;
  final String iconKey;
  final int colorValue;
  final int sortOrder;

  Color get color => Color(colorValue);

  IconData get icon => switch (iconKey) {
    'cleaning_services' => Icons.cleaning_services_rounded,
    'handyman' => Icons.handyman_rounded,
    'local_laundry_service' => Icons.local_laundry_service_rounded,
    'home_repair_service' => Icons.home_repair_service_rounded,
    'ac_unit' => Icons.ac_unit_rounded,
    'pest_control' => Icons.pest_control_rounded,
    _ => Icons.home_repair_service_rounded,
  };

  @override
  List<Object?> get props => [id, name, slug, iconKey, colorValue, sortOrder];
}
