import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final class StaffBottomNavigation extends StatelessWidget {
  const StaffBottomNavigation({required this.index, super.key});

  final int index;

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: index,
    onDestinationSelected: (value) {
      switch (value) {
        case 0:
          context.go('/staff');
        case 1:
          context.go('/staff/incoming');
        case 2:
          context.go('/staff/history');
        case 3:
          context.go('/staff/profile');
      }
    },
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard_rounded),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(Icons.inbox_outlined),
        selectedIcon: Icon(Icons.inbox_rounded),
        label: 'Pesanan',
      ),
      NavigationDestination(
        icon: Icon(Icons.history_rounded),
        label: 'Riwayat',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'Profil',
      ),
    ],
  );
}
