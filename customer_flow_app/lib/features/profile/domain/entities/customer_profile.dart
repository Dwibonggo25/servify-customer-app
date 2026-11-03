import 'package:equatable/equatable.dart';

final class CustomerProfile extends Equatable {
  const CustomerProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? phone;
  final String? avatarUrl;

  String get initial {
    final value = fullName.trim().isNotEmpty ? fullName.trim() : email.trim();
    return value.isEmpty ? 'C' : value[0].toUpperCase();
  }

  CustomerProfile copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) {
    return CustomerProfile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      role: role,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  List<Object?> get props => [id, email, fullName, role, phone, avatarUrl];
}
