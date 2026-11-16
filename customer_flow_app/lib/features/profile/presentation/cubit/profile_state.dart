import 'package:equatable/equatable.dart';

import '../../domain/entities/customer_profile.dart';

enum ProfileStatus { initial, loading, loaded, saving, saved, failure }

enum ProfileAction { none, updateDetails, uploadAvatar }

final class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.action = ProfileAction.none,
    this.profile,
    this.message,
  });

  final ProfileStatus status;
  final ProfileAction action;
  final CustomerProfile? profile;
  final String? message;

  bool get isLoading =>
      status == ProfileStatus.initial || status == ProfileStatus.loading;
  bool get isSaving => status == ProfileStatus.saving;
  bool get isUploadingAvatar =>
      isSaving && action == ProfileAction.uploadAvatar;

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileAction? action,
    CustomerProfile? profile,
    String? message,
  }) {
    return ProfileState(
      status: status ?? this.status,
      action: action ?? this.action,
      profile: profile ?? this.profile,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, action, profile, message];
}
