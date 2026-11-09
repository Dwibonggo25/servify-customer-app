import 'dart:typed_data';

import '../entities/service_item.dart';
import '../entities/service_draft.dart';

abstract interface class ServiceRepository {
  Future<List<ServiceItem>> getActiveServices();

  Future<ServiceItem?> getActiveServiceById(String id);

  Future<List<ServiceItem>> getAllServicesForAdmin();

  Future<String> saveService({String? id, required ServiceDraft draft});

  Future<String> uploadServiceImage({
    required Uint8List bytes,
    required String fileExtension,
  });

  Future<void> deleteService(String id);
}
