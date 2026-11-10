import 'package:flutter/material.dart';
import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';

final class AppBarWidget extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final IconData icons;
  final String subtitle;
  final List<Widget>? actions;

  const AppBarWidget({
    super.key,
    required this.title,
    required this.icons,
    required this.subtitle,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(112);

  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    toolbarHeight: preferredSize.height,
    foregroundColor: Colors.white,
    backgroundColor: AppColors.primary,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    actions: actions,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
    ),
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B4CF0), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
    ),
    titleSpacing: 20,
    title: Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Icon(icons, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(title),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr(subtitle),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFEDE9FE),
                  fontSize: 12,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
