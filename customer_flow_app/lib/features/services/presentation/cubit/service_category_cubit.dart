import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../libraries/core/localization/language_controller.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../domain/repositories/service_category_repository.dart';
import 'service_category_state.dart';

final class ServiceCategoryCubit extends Cubit<ServiceCategoryState> {
  ServiceCategoryCubit(this._repository) : super(const ServiceCategoryState());

  final ServiceCategoryRepository _repository;

  Future<void> load() async {
    emit(const ServiceCategoryState(status: ServiceCategoryStatus.loading));
    try {
      final categories = await _repository.getActiveCategories();
      emit(
        ServiceCategoryState(
          status: ServiceCategoryStatus.success,
          categories: categories,
        ),
      );
    } catch (_) {
      emit(
        ServiceCategoryState(
          status: ServiceCategoryStatus.failure,
          message: LanguageController.instance.translate(
            LanguageKeys.categoryLoadFailed,
          ),
        ),
      );
    }
  }
}
