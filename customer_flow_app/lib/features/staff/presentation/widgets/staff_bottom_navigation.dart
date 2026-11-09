import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../libraries/design_system/theme/app_colors.dart';

final class StaffBottomNavigation extends StatelessWidget {
  const StaffBottomNavigation({required this.index, super.key});

  final int index;

  @override
  Widget build(BuildContext context) {
    const contentHeight = 80.0;
    final navigationHeight =
        contentHeight + MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: navigationHeight,
      child: BottomAppBar(
        height: navigationHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: AppColors.primary,
        surfaceTintColor: Colors.transparent,
        shape: const AutomaticNotchedShape(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(32)),
          ),
        ),
        child: Row(
          children: [
            _StaffNavigationButton(
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard_rounded,
              label: 'Dashboard',
              selected: index == 0,
              onTap: () => context.go('/staff'),
            ),
            _StaffNavigationButton(
              icon: Icons.inbox_outlined,
              selectedIcon: Icons.inbox_rounded,
              label: 'Pesanan',
              selected: index == 1,
              onTap: () => context.go('/staff/incoming'),
            ),
            _StaffNavigationButton(
              icon: Icons.history_outlined,
              selectedIcon: Icons.history_rounded,
              label: 'Riwayat',
              selected: index == 2,
              onTap: () => context.go('/staff/history'),
            ),
            _StaffNavigationButton(
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
              label: 'Profil',
              selected: index == 3,
              onTap: () => context.go('/staff/profile'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _StaffNavigationButton extends StatelessWidget {
  const _StaffNavigationButton({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const activeColor = Colors.white;
    const inactiveColor = Color(0xFFD8D6FF);

    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 34,
                height: 31,
                child: Icon(
                  selected ? selectedIcon : icon,
                  color: selected ? activeColor : inactiveColor,
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? activeColor : inactiveColor,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
