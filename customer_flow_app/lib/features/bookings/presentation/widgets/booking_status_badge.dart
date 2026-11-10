import 'package:flutter/material.dart';

import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';

final class BookingStatusBadge extends StatelessWidget {
  const BookingStatusBadge({required this.status, super.key});

  final String status;

  static String label(BuildContext context, String status) {
    final localizations =
        AppLocalizations.maybeOf(context) ??
        const AppLocalizations(Locale('id'));
    return localizations.translate(switch (status) {
      'pending' => LanguageKeys.statusPending,
      'confirmed' => LanguageKeys.statusConfirmed,
      'assigned' => LanguageKeys.statusAssigned,
      'on_the_way' => LanguageKeys.statusOnTheWay,
      'in_progress' => LanguageKeys.statusInProgress,
      'completed' => LanguageKeys.completed,
      'cancelled' => LanguageKeys.cancelled,
      _ => status,
    });
  }

  @override
  Widget build(BuildContext context) {
    final (foreground, background) = switch (status) {
      'completed' => (const Color(0xFF15803D), const Color(0xFFDCFCE7)),
      'cancelled' => (const Color(0xFFB91C1C), const Color(0xFFFEE2E2)),
      'on_the_way' ||
      'in_progress' => (const Color(0xFF1D4ED8), const Color(0xFFDBEAFE)),
      _ => (const Color(0xFFB45309), const Color(0xFFFEF3C7)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label(context, status),
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
