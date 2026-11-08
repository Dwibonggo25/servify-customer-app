import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../libraries/core/localization/language_controller.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../domain/repositories/service_repository.dart';
import 'service_catalog_state.dart';

final class ServiceCatalogCubit extends Cubit<ServiceCatalogState> {
  ServiceCatalogCubit(this._repository) : super(const ServiceCatalogState());

  final ServiceRepository _repository;

  Future<void> load() async {
    emit(const ServiceCatalogState(status: ServiceCatalogStatus.loading));
    try {
      final services = await _repository.getActiveServices();
      emit(
        ServiceCatalogState(
          status: ServiceCatalogStatus.success,
          services: services,
        ),
      );
    } catch (_) {
      emit(
        ServiceCatalogState(
          status: ServiceCatalogStatus.failure,
          message: LanguageController.instance.translate(
            LanguageKeys.serviceLoadFailed,
          ),
        ),
      );
    }
  }
}
