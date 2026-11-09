import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../profile/domain/entities/customer_profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';

final class RoleGatePage extends StatefulWidget {
  const RoleGatePage({required this.profileRepository, super.key});

  final ProfileRepository profileRepository;

  @override
  State<RoleGatePage> createState() => _RoleGatePageState();
}

final class _RoleGatePageState extends State<RoleGatePage> {
  late Future<CustomerProfile> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.profileRepository.getProfile();
    _route();
  }

  Future<void> _route() async {
    try {
      final profile = await _future;
      if (!mounted) return;
      final destination = switch (profile.role) {
        'admin' => '/admin',
        'staff' => '/staff',
        _ => '/home',
      };
      context.go(destination);
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: FutureBuilder<CustomerProfile>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return FilledButton.icon(
              onPressed: () {
                final nextLoad = widget.profileRepository.getProfile();
                setState(() {
                  _future = nextLoad;
                });
                _route();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi'),
            );
          }
          return const CircularProgressIndicator();
        },
      ),
    ),
  );
}
