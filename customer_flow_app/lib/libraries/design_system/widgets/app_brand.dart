import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../theme/app_colors.dart';

final class AppBrand extends StatelessWidget {
  const AppBrand({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 44 : 64,
          height: compact ? 44 : 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(compact ? 14 : 20),
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: compact ? 24 : 34,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          AppConstants.appName,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
