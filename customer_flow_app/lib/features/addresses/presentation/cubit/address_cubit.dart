import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../libraries/core/localization/language_controller.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../domain/entities/address_draft.dart';
import '../../domain/repositories/address_repository.dart';
import 'address_state.dart';

final class AddressCubit extends Cubit<AddressState> {
  AddressCubit(this._repository) : super(const AddressState());

  final AddressRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: AddressStatus.loading, message: null));
    try {
      final addresses = await _repository.getAddresses();
      emit(AddressState(status: AddressStatus.loaded, addresses: addresses));
    } catch (_) {
      emit(
        state.copyWith(
          status: AddressStatus.failure,
          message: _tr(LanguageKeys.addressLoadFailed),
        ),
      );
    }
  }

  Future<bool> save({String? id, required AddressDraft draft}) async {
    emit(state.copyWith(status: AddressStatus.saving, message: null));
    try {
      if (id == null) {
        await _repository.createAddress(draft);
      } else {
        await _repository.updateAddress(id, draft);
      }
      final addresses = await _repository.getAddresses();
      emit(
        AddressState(
          status: AddressStatus.loaded,
          addresses: addresses,
          message: _tr(
            id == null
                ? LanguageKeys.addressAdded
                : LanguageKeys.addressUpdated,
          ),
        ),
      );
      return true;
    } catch (_) {
      emit(
        state.copyWith(
          status: AddressStatus.failure,
          message: _tr(LanguageKeys.addressSaveFailed),
        ),
      );
      return false;
    }
  }

  Future<void> setDefault(String id) async {
    emit(state.copyWith(status: AddressStatus.saving, message: null));
    try {
      await _repository.setDefaultAddress(id);
      final addresses = await _repository.getAddresses();
      emit(
        AddressState(
          status: AddressStatus.loaded,
          addresses: addresses,
          message: _tr(LanguageKeys.defaultAddressUpdated),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AddressStatus.failure,
          message: _tr(LanguageKeys.addressSaveFailed),
        ),
      );
    }
  }

  Future<void> delete(String id) async {
    emit(state.copyWith(status: AddressStatus.saving, message: null));
    try {
      await _repository.deleteAddress(id);
      final addresses = await _repository.getAddresses();
      emit(
        AddressState(
          status: AddressStatus.loaded,
          addresses: addresses,
          message: _tr(LanguageKeys.addressDeleted),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AddressStatus.failure,
          message: _tr(LanguageKeys.addressDeleteFailed),
        ),
      );
    }
  }

  String _tr(String key) => LanguageController.instance.translate(key);
}
