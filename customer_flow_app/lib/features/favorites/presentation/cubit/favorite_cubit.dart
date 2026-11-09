import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/favorite_repository.dart';
import 'favorite_state.dart';

final class FavoriteCubit extends Cubit<FavoriteState> {
  FavoriteCubit(this._repository) : super(const FavoriteState());

  final FavoriteRepository _repository;

  Future<void> load() async {
    emit(
      FavoriteState(
        status: FavoriteStatus.loading,
        serviceIds: state.serviceIds,
      ),
    );
    try {
      final serviceIds = await _repository.getFavoriteServiceIds();
      emit(
        FavoriteState(status: FavoriteStatus.success, serviceIds: serviceIds),
      );
    } catch (error, stackTrace) {
      _log(error, stackTrace);
      emit(
        FavoriteState(
          status: FavoriteStatus.failure,
          serviceIds: state.serviceIds,
          message: 'Favorit gagal dimuat.',
        ),
      );
    }
  }

  Future<void> toggle(String serviceId) async {
    final previousIds = state.serviceIds;
    final optimisticIds = Set<String>.of(previousIds);
    if (!optimisticIds.add(serviceId)) optimisticIds.remove(serviceId);
    emit(
      FavoriteState(status: FavoriteStatus.success, serviceIds: optimisticIds),
    );

    try {
      final serviceIds = await _repository.toggleFavorite(serviceId);
      emit(
        FavoriteState(status: FavoriteStatus.success, serviceIds: serviceIds),
      );
    } catch (error, stackTrace) {
      _log(error, stackTrace);
      emit(
        FavoriteState(
          status: FavoriteStatus.failure,
          serviceIds: previousIds,
          message: 'Favorit gagal diperbarui.',
        ),
      );
    }
  }

  void _log(Object error, StackTrace stackTrace) {
    developer.log(
      'Operasi favorit gagal',
      name: 'FavoriteCubit',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
