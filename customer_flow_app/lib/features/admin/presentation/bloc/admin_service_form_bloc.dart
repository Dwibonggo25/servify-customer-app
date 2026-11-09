import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../services/domain/entities/service_draft.dart';
import '../../../services/domain/repositories/service_category_repository.dart';
import '../../../services/domain/repositories/service_repository.dart';
import 'admin_service_form_event.dart';
import 'admin_service_form_state.dart';

final class AdminServiceFormBloc
    extends Bloc<AdminServiceFormEvent, AdminServiceFormState> {
  AdminServiceFormBloc({
    required ServiceRepository serviceRepository,
    required ServiceCategoryRepository categoryRepository,
  }) : _serviceRepository = serviceRepository,
       _categoryRepository = categoryRepository,
       super(const AdminServiceFormState()) {
    on<AdminServiceFormStarted>(_onStarted);
    on<AdminServiceSubmitted>(_onSubmitted);
  }

  final ServiceRepository _serviceRepository;
  final ServiceCategoryRepository _categoryRepository;

  Future<void> _onStarted(
    AdminServiceFormStarted event,
    Emitter<AdminServiceFormState> emit,
  ) async {
    emit(state.copyWith(status: AdminServiceFormStatus.loading));
    try {
      final categories = await _categoryRepository.getActiveCategories();
      emit(
        AdminServiceFormState(
          status: AdminServiceFormStatus.ready,
          categories: categories,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AdminServiceFormStatus.failure,
          message: 'Gagal memuat kategori layanan: $error',
        ),
      );
    }
  }

  Future<void> _onSubmitted(
    AdminServiceSubmitted event,
    Emitter<AdminServiceFormState> emit,
  ) async {
    emit(state.copyWith(status: AdminServiceFormStatus.saving));
    try {
      var imageUrl = event.draft.imageUrl;
      if (event.imageBytes case final bytes?) {
        imageUrl = await _serviceRepository.uploadServiceImage(
          bytes: bytes,
          fileExtension: event.imageExtension ?? 'jpg',
        );
      }

      final draft = ServiceDraft(
        categoryId: event.draft.categoryId,
        name: event.draft.name,
        slug: event.draft.slug,
        shortDescription: event.draft.shortDescription,
        description: event.draft.description,
        price: event.draft.price,
        durationMinutes: event.draft.durationMinutes,
        iconKey: event.draft.iconKey,
        imageUrl: imageUrl,
        colorValue: event.draft.colorValue,
        includes: event.draft.includes,
        isActive: event.draft.isActive,
      );
      await _serviceRepository.saveService(id: event.serviceId, draft: draft);
      emit(
        AdminServiceFormState(
          status: AdminServiceFormStatus.success,
          categories: state.categories,
          message: event.serviceId == null
              ? 'Layanan berhasil ditambahkan.'
              : 'Perubahan layanan berhasil disimpan.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AdminServiceFormStatus.failure,
          message: 'Gagal menyimpan layanan: $error',
        ),
      );
    }
  }
}
