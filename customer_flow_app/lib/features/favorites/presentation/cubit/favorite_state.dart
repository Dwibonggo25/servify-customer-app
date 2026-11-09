import 'package:equatable/equatable.dart';

enum FavoriteStatus { initial, loading, success, failure }

final class FavoriteState extends Equatable {
  const FavoriteState({
    this.status = FavoriteStatus.initial,
    this.serviceIds = const <String>{},
    this.message,
  });

  final FavoriteStatus status;
  final Set<String> serviceIds;
  final String? message;

  bool get isLoading =>
      status == FavoriteStatus.initial || status == FavoriteStatus.loading;

  bool contains(String serviceId) => serviceIds.contains(serviceId);

  @override
  List<Object?> get props => [status, serviceIds, message];
}
