import 'dart:async';

import 'package:customer_flow_app/features/auth/domain/entities/app_user.dart';
import 'package:customer_flow_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:customer_flow_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:customer_flow_app/features/profile/domain/entities/customer_profile.dart';
import 'package:customer_flow_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:customer_flow_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:customer_flow_app/features/staff/presentation/ui/staff_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('staff profile fits an iPhone-sized screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final authRepository = _FakeAuthRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => ProfileCubit(_FakeProfileRepository())..load(),
            ),
            BlocProvider(create: (_) => AuthBloc(authRepository)),
          ],
          child: const StaffProfilePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profil Staff'), findsOneWidget);
    expect(find.text('Dwi Staff'), findsNWidgets(2));
    expect(find.text('Terverifikasi'), findsOneWidget);
    expect(find.text('Informasi akun'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await authRepository.dispose();
  });
}

final class _FakeProfileRepository implements ProfileRepository {
  CustomerProfile profile = const CustomerProfile(
    id: 'staff-1',
    email: 'staff@servify.test',
    fullName: 'Dwi Staff',
    role: 'staff',
    phone: '08123456789',
  );

  @override
  Future<CustomerProfile> getProfile() async => profile;

  @override
  Future<CustomerProfile> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    profile = profile.copyWith(fullName: fullName, phone: phone);
    return profile;
  }
}

final class _FakeAuthRepository implements AuthRepository {
  final StreamController<AppUser?> _controller = StreamController.broadcast();

  @override
  AppUser? get currentUser =>
      const AppUser(id: 'staff-1', email: 'staff@servify.test');

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async => AppUser(id: 'staff-1', email: email);

  @override
  Future<AppUser?> register({
    required String fullName,
    required String email,
    required String password,
  }) async => AppUser(id: 'staff-1', email: email, fullName: fullName);

  @override
  Future<void> signOut() async {}

  Future<void> dispose() => _controller.close();
}
