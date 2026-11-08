import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/service_item.dart';
import '../../domain/repositories/service_repository.dart';

final class SupabaseServiceRepository implements ServiceRepository {
  const SupabaseServiceRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ServiceItem>> getActiveServices() async {
    final rows = await _client
        .from('services')
        .select(
          'id, name, short_description, description, base_price, '
          'duration_minutes, rating, review_count, icon_key, color_value, '
          'service_categories!inner(name)',
        )
        .eq('is_active', true)
        .order('created_at');

    if (rows.isEmpty) return const [];

    final serviceIds = rows
        .map((row) => row['id'] as String)
        .toList(growable: false);
    final inclusionRows = await _client
        .from('service_inclusions')
        .select('service_id, label, sort_order')
        .inFilter('service_id', serviceIds)
        .order('sort_order');

    final inclusionsByService = <String, List<String>>{};
    for (final row in inclusionRows) {
      final serviceId = row['service_id'] as String;
      inclusionsByService
          .putIfAbsent(serviceId, () => <String>[])
          .add(row['label'] as String);
    }

    return rows
        .map(
          (row) => _mapService(
            row,
            inclusionsByService[row['id'] as String] ?? const [],
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<ServiceItem?> getActiveServiceById(String id) async {
    final rows = await _client
        .from('services')
        .select(
          'id, name, short_description, description, base_price, '
          'duration_minutes, rating, review_count, icon_key, color_value, '
          'service_categories!inner(name)',
        )
        .eq('id', id)
        .eq('is_active', true)
        .limit(1);

    if (rows.isEmpty) return null;

    final inclusionRows = await _client
        .from('service_inclusions')
        .select('label, sort_order')
        .eq('service_id', id)
        .order('sort_order');
    final inclusions = inclusionRows
        .map((row) => row['label'] as String)
        .toList(growable: false);

    return _mapService(rows.first, inclusions);
  }

  ServiceItem _mapService(Map<String, dynamic> row, List<String> inclusions) {
    final category = row['service_categories'] as Map<String, dynamic>;
    return ServiceItem(
      id: row['id'] as String,
      name: row['name'] as String,
      shortDescription: row['short_description'] as String,
      description: row['description'] as String,
      category: category['name'] as String,
      price: (row['base_price'] as num).toInt(),
      durationMinutes: (row['duration_minutes'] as num).toInt(),
      rating: (row['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (row['review_count'] as num?)?.toInt() ?? 0,
      icon: _iconFor(row['icon_key'] as String),
      color: Color((row['color_value'] as num).toInt()),
      includes: inclusions,
    );
  }

  IconData _iconFor(String key) => switch (key) {
    'cleaning_services' => Icons.cleaning_services_rounded,
    'handyman' => Icons.handyman_rounded,
    'local_laundry_service' => Icons.local_laundry_service_rounded,
    'home_repair_service' => Icons.home_repair_service_rounded,
    'ac_unit' => Icons.ac_unit_rounded,
    'pest_control' => Icons.pest_control_rounded,
    _ => Icons.home_repair_service_rounded,
  };
}
