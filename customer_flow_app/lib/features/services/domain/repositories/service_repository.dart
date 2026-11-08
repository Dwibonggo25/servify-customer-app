import '../entities/service_item.dart';

abstract interface class ServiceRepository {
  Future<List<ServiceItem>> getActiveServices();

  Future<ServiceItem?> getActiveServiceById(String id);
}
