import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../../libraries/design_system/widgets/app_button.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../profile/domain/entities/customer_profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../widgets/staff_bottom_navigation.dart';

final class StaffProfilePage extends StatefulWidget {
  const StaffProfilePage({
    required this.profileRepository,
    required this.authRepository,
    super.key,
  });

  final ProfileRepository profileRepository;
  final AuthRepository authRepository;

  @override
  State<StaffProfilePage> createState() => _StaffProfilePageState();
}

final class _StaffProfilePageState extends State<StaffProfilePage> {
  late Future<CustomerProfile> _future;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _future = widget.profileRepository.getProfile();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profil staff')),
    body: FutureBuilder<CustomerProfile>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: FilledButton(
              onPressed: () {
                final nextLoad = widget.profileRepository.getProfile();
                setState(() {
                  _future = nextLoad;
                });
              },
              child: const Text('Coba lagi'),
            ),
          );
        }
        final profile = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Text(
                      profile.initial,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.email,
                          style: const TextStyle(color: Color(0xFFE7E5FF)),
                        ),
                        const SizedBox(height: 8),
                        const Chip(label: Text('Staff terverifikasi')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: const Text('Nomor telepon'),
              subtitle: Text(profile.phone ?? 'Belum ditambahkan'),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Keluar dari akun',
              icon: Icons.logout_rounded,
              isOutlined: true,
              isLoading: _loggingOut,
              onPressed: _logout,
            ),
          ],
        );
      },
    ),
    bottomNavigationBar: const StaffBottomNavigation(index: 3),
  );

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    try {
      await widget.authRepository.signOut();
      if (mounted) context.go('/login');
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }
}
