import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/service_item.dart';
import '../../domain/entities/service_draft.dart';
import '../../domain/repositories/service_repository.dart';

final class SupabaseServiceRepository implements ServiceRepository {
  const SupabaseServiceRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ServiceItem>> getActiveServices() async {
    final rows = await _client
        .from('services')
        .select(
          'id, category_id, name, slug, short_description, description, '
          'base_price, '
          'duration_minutes, rating, review_count, icon_key, color_value, '
          'image_url, is_active, service_categories!inner(name)',
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
          'id, category_id, name, slug, short_description, description, '
          'base_price, '
          'duration_minutes, rating, review_count, icon_key, color_value, '
          'image_url, is_active, service_categories!inner(name)',
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

  @override
  Future<List<ServiceItem>> getAllServicesForAdmin() async {
    final rows = await _client
        .from('services')
        .select(
          'id, category_id, name, slug, short_description, description, '
          'base_price, duration_minutes, rating, review_count, icon_key, '
          'color_value, image_url, is_active, service_categories!inner(name)',
        )
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
  Future<String> saveService({String? id, required ServiceDraft draft}) async {
    final result = await _client.rpc<dynamic>(
      'admin_save_service',
      params: {
        'p_service_id': id,
        'p_category_id': draft.categoryId,
        'p_name': draft.name,
        'p_slug': draft.slug,
        'p_short_description': draft.shortDescription,
        'p_description': draft.description,
        'p_base_price': draft.price,
        'p_duration_minutes': draft.durationMinutes,
        'p_icon_key': draft.iconKey,
        'p_image_url': draft.imageUrl,
        'p_color_value': draft.colorValue,
        'p_is_active': draft.isActive,
        'p_inclusions': draft.includes,
      },
    );
    return result as String;
  }

  @override
  Future<String> uploadServiceImage({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Sesi admin tidak ditemukan.');

    final extension = _normalizedExtension(fileExtension);
    final path = '$userId/${DateTime.now().microsecondsSinceEpoch}.$extension';
    await _client.storage
        .from('service-images')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _contentType(extension),
            upsert: false,
          ),
        );
    return _client.storage.from('service-images').getPublicUrl(path);
  }

  @override
  Future<void> deleteService(String id) async {
    await _client.rpc<dynamic>(
      'admin_delete_service',
      params: {'p_service_id': id},
    );
  }

  ServiceItem _mapService(Map<String, dynamic> row, List<String> inclusions) {
    final category = row['service_categories'] as Map<String, dynamic>;
    return ServiceItem(
      id: row['id'] as String,
      categoryId: row['category_id'] as String,
      name: row['name'] as String,
      slug: row['slug'] as String,
      shortDescription: row['short_description'] as String,
      description: row['description'] as String,
      category: category['name'] as String,
      price: (row['base_price'] as num).toInt(),
      durationMinutes: (row['duration_minutes'] as num).toInt(),
      rating: (row['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (row['review_count'] as num?)?.toInt() ?? 0,
      icon: _iconFor(row['icon_key'] as String),
      imageUrl: (row['image_url'] as String?)?.trim().isNotEmpty == true
          ? (row['image_url'] as String).trim()
          : null,
      color: Color((row['color_value'] as num).toInt()),
      includes: inclusions,
      isActive: row['is_active'] as bool? ?? true,
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

  String _normalizedExtension(String value) {
    final extension = value.toLowerCase().replaceFirst('.', '');
    return switch (extension) {
      'png' => 'png',
      'webp' => 'webp',
      'heic' || 'heif' => 'heic',
      _ => 'jpg',
    };
  }

  String _contentType(String extension) => switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    _ => 'image/jpeg',
  };
}
