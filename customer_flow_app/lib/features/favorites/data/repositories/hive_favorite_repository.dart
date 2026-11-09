import 'package:hive_ce/hive.dart';

import '../../domain/repositories/favorite_repository.dart';

final class HiveFavoriteRepository implements FavoriteRepository {
  const HiveFavoriteRepository({
    required Box<dynamic> box,
    required String Function() ownerId,
  }) : _box = box,
       _ownerId = ownerId;

  final Box<dynamic> _box;
  final String Function() _ownerId;

  String get _storageKey => 'favorite_service_ids:${_ownerId()}';

  @override
  Future<Set<String>> getFavoriteServiceIds() async {
    final stored = _box.get(_storageKey);
    if (stored is! List) return <String>{};
    return stored.whereType<String>().toSet();
  }

  @override
  Future<Set<String>> toggleFavorite(String serviceId) async {
    final favoriteIds = await getFavoriteServiceIds();
    if (!favoriteIds.add(serviceId)) favoriteIds.remove(serviceId);
    await _box.put(_storageKey, favoriteIds.toList(growable: false));
    return favoriteIds;
  }
}
