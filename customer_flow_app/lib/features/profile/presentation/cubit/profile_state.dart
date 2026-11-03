import 'package:equatable/equatable.dart';

import '../../domain/entities/customer_profile.dart';

enum ProfileStatus { initial, loading, loaded, saving, saved, failure }

final class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.message,
  });

  final ProfileStatus status;
  final CustomerProfile? profile;
  final String? message;

  bool get isLoading =>
      status == ProfileStatus.initial || status == ProfileStatus.loading;
  bool get isSaving => status == ProfileStatus.saving;

  ProfileState copyWith({
    ProfileStatus? status,
    CustomerProfile? profile,
    String? message,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, profile, message];
}
