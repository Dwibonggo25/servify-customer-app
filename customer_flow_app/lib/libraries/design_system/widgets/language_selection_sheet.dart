import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/localization/language_controller.dart';
import '../../core/localization/language_keys.dart';
import '../theme/app_colors.dart';

final class LanguageSelectionSheet extends StatelessWidget {
  const LanguageSelectionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLanguage = LanguageController.instance.value.languageCode;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(LanguageKeys.language),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr(LanguageKeys.languageDescription),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            _LanguageOption(
              title: context.tr(LanguageKeys.indonesian),
              languageCode: 'id',
              isSelected: currentLanguage == 'id',
            ),
            _LanguageOption(
              title: context.tr(LanguageKeys.english),
              languageCode: 'en',
              isSelected: currentLanguage == 'en',
            ),
          ],
        ),
      ),
    );
  }
}

final class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.title,
    required this.languageCode,
    required this.isSelected,
  });

  final String title;
  final String languageCode;
  final bool isSelected;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(
      backgroundColor: const Color(0xFFEDEBFF),
      child: Text(
        languageCode.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    trailing: isSelected
        ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
        : null,
    onTap: () {
      Navigator.of(context).pop();
      LanguageController.instance.changeLanguage(languageCode);
    },
  );
}
