import '../entities/service_category.dart';

abstract interface class ServiceCategoryRepository {
  Future<List<ServiceCategory>> getActiveCategories();
}
