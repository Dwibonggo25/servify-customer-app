import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/service_category.dart';
import '../../domain/repositories/service_category_repository.dart';

final class SupabaseServiceCategoryRepository
    implements ServiceCategoryRepository {
  const SupabaseServiceCategoryRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ServiceCategory>> getActiveCategories() async {
    final rows = await _client
        .from('service_categories')
        .select('id, name, slug, icon_key, color_value, sort_order')
        .eq('is_active', true)
        .order('sort_order')
        .order('name');

    return rows.map(_mapCategory).toList(growable: false);
  }

  ServiceCategory _mapCategory(Map<String, dynamic> row) {
    return ServiceCategory(
      id: row['id'] as String,
      name: row['name'] as String,
      slug: row['slug'] as String,
      iconKey: row['icon_key'] as String,
      colorValue: (row['color_value'] as num).toInt(),
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
