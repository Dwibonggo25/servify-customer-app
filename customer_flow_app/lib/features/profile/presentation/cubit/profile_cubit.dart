import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../libraries/core/localization/language_controller.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_state.dart';

final class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository) : super(const ProfileState());

  final ProfileRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      final profile = await _repository.getProfile();
      emit(ProfileState(status: ProfileStatus.loaded, profile: profile));
    } catch (_) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          message: LanguageController.instance.translate(
            LanguageKeys.profileLoadFailed,
          ),
        ),
      );
    }
  }

  Future<void> update({required String fullName, required String phone}) async {
    emit(state.copyWith(status: ProfileStatus.saving));
    try {
      final profile = await _repository.updateProfile(
        fullName: fullName,
        phone: phone,
      );
      emit(
        ProfileState(
          status: ProfileStatus.saved,
          profile: profile,
          message: LanguageController.instance.translate(
            LanguageKeys.profileUpdated,
          ),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          message: LanguageController.instance.translate(
            LanguageKeys.profileUpdateFailed,
          ),
        ),
      );
    }
  }
}
