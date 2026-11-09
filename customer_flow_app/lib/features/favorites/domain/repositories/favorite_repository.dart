abstract interface class FavoriteRepository {
  Future<Set<String>> getFavoriteServiceIds();

  Future<Set<String>> toggleFavorite(String serviceId);
}
