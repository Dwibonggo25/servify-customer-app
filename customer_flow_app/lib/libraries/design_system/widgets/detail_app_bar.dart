import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

final class DetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const DetailAppBar({
    required this.title,
    required this.subtitle,
    this.onBack,
    this.actions,
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(116);

  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    toolbarHeight: preferredSize.height,
    foregroundColor: Colors.white,
    backgroundColor: AppColors.primary,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    leadingWidth: 64,
    leading: Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Center(
        child: Material(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: onBack ?? () => Navigator.maybePop(context),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
        ),
      ),
    ),
    actions: actions,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
    ),
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
    ),
    titleSpacing: 8,
    title: Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFEDE9FE),
                  fontSize: 11.5,
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
