import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../libraries/core/formatters/app_formatters.dart';
import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../../libraries/design_system/widgets/app_button.dart';
import '../../domain/entities/service_item.dart';

final class ServiceDetailPage extends StatelessWidget {
  const ServiceDetailPage({required this.service, super.key});

  final ServiceItem service;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr(LanguageKeys.serviceDetail))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Container(
            height: 210,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [service.color, service.color.withValues(alpha: 0.72)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(service.icon, color: Colors.white, size: 92),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  service.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFF59E0B),
                      size: 18,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      service.rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(LanguageKeys.reviewsAndEstimate, {
              'reviews': service.reviewCount,
              'duration': _durationLabel(context, service.durationMinutes),
            }),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Text(
            service.description,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.6),
          ),
          const SizedBox(height: 28),
          Text(
            context.tr(LanguageKeys.whatYouGet),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          ...service.includes.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 21,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(LanguageKeys.startingAt, {'price': ''}).trim(),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    Text(
                      AppFormatters.rupiah(service.price),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 6,
                child: AppButton(
                  label: context.tr(LanguageKeys.bookNow),
                  onPressed: () => context.push('/services/${service.id}/book'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _durationLabel(BuildContext context, int minutes) {
    if (minutes >= 1440) {
      return context.tr(LanguageKeys.day, {'count': minutes ~/ 1440});
    }
    if (minutes >= 60) {
      return context.tr(LanguageKeys.hour, {'count': minutes ~/ 60});
    }
    return context.tr(LanguageKeys.minute, {'count': minutes});
  }
}
