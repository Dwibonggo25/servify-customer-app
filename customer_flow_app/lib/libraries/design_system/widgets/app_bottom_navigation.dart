import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/localization/language_keys.dart';
import '../theme/app_colors.dart';

final class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onScanPressed,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onScanPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomAppBar(
              height: 80,
              padding: EdgeInsets.zero,
              color: AppColors.primary,
              surfaceTintColor: Colors.transparent,
              shape: const AutomaticNotchedShape(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(32)),
                ),
                CircleBorder(),
              ),
              notchMargin: 7,
              child: Row(
                children: [
                  _NavigationButton(
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    label: context.tr(LanguageKeys.home),
                    selected: selectedIndex == 0,
                    onTap: () => onDestinationSelected(0),
                  ),
                  _NavigationButton(
                    icon: Icons.receipt_long_outlined,
                    selectedIcon: Icons.receipt_long_rounded,
                    label: context.tr(LanguageKeys.orders),
                    selected: selectedIndex == 1,
                    onTap: () => onDestinationSelected(1),
                  ),
                  const SizedBox(width: 68),
                  _NavigationButton(
                    icon: Icons.favorite_border_rounded,
                    selectedIcon: Icons.favorite_rounded,
                    label: context.tr(LanguageKeys.favorites),
                    selected: selectedIndex == 2,
                    onTap: () => onDestinationSelected(2),
                  ),
                  _NavigationButton(
                    icon: Icons.person_outline_rounded,
                    selectedIcon: Icons.person_rounded,
                    label: context.tr(LanguageKeys.profile),
                    selected: selectedIndex == 3,
                    onTap: () => onDestinationSelected(3),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: FloatingActionButton(
              onPressed: onScanPressed,
              tooltip: context.tr(LanguageKeys.scanQr),
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              elevation: 5,
              shape: const CircleBorder(
                side: BorderSide(color: Colors.white, width: 4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner_rounded, size: 25),
                  Text(
                    context.tr(LanguageKeys.scan),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Semantics(
          selected: selected,
          button: true,
          label: label,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 34,
                height: 31,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
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
