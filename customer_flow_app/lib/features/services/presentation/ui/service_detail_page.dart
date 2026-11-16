import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../libraries/core/formatters/app_formatters.dart';
import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../../libraries/design_system/widgets/detail_app_bar.dart';
import '../../../favorites/presentation/cubit/favorite_cubit.dart';
import '../../../favorites/presentation/cubit/favorite_state.dart';
import '../../domain/entities/service_item.dart';
import '../cubit/service_catalog_cubit.dart';
import '../cubit/service_catalog_state.dart';
import '../widgets/service_image.dart';

final class ServiceDetailPage extends StatelessWidget {
  const ServiceDetailPage({required this.service, super.key});

  final ServiceItem service;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DetailAppBar(
        title: context.tr(LanguageKeys.serviceDetail),
        subtitle: context.tr(LanguageKeys.serviceDetailSubtitle),
        actions: [
          BlocBuilder<FavoriteCubit, FavoriteState>(
            buildWhen: (previous, current) =>
                previous.contains(service.id) != current.contains(service.id),
            builder: (context, state) {
              final isFavorite = state.contains(service.id);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: context.tr(
                      isFavorite
                          ? LanguageKeys.removeFavorite
                          : LanguageKeys.addFavorite,
                    ),
                    onPressed: () =>
                        context.read<FavoriteCubit>().toggle(service.id),
                    color: Colors.white,
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: [
          _ServiceHero(service: service),
          const SizedBox(height: 22),
          _ServiceHeading(service: service),
          const SizedBox(height: 18),
          _ServiceMetrics(service: service),
          const SizedBox(height: 26),
          _AboutService(service: service),
          const SizedBox(height: 16),
          _ServiceInclusions(service: service),
          const SizedBox(height: 16),
          const _TrustCard(),
          const SizedBox(height: 30),
          _SimilarServicesSection(service: service),
        ],
      ),
      bottomNavigationBar: _BookingBar(service: service),
    );
  }
}

final class _ServiceHero extends StatelessWidget {
  const _ServiceHero({required this.service});

  final ServiceItem service;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 232,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ServiceImage(
            imageUrl: service.imageUrl,
            fallbackIcon: service.icon,
            color: service.color,
            iconSize: 92,
            borderRadius: BorderRadius.circular(28),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x990F1020)],
                stops: [0.48, 1],
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 16,
            child: _HeroBadge(
              icon: Icons.grid_view_rounded,
              label: service.category,
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: _HeroBadge(
              icon: Icons.star_rounded,
              label: service.rating.toStringAsFixed(1),
              iconColor: const Color(0xFFFBBF24),
            ),
          ),
        ],
      ),
    );
  }
}

final class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.icon,
    required this.label,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xCC222334),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

final class _ServiceHeading extends StatelessWidget {
  const _ServiceHeading({required this.service});

  final ServiceItem service;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          service.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            height: 1.18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          service.shortDescription,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

final class _ServiceMetrics extends StatelessWidget {
  const _ServiceMetrics({required this.service});

  final ServiceItem service;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricItem(
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFF59E0B),
            value: service.rating.toStringAsFixed(1),
            label: context.tr(LanguageKeys.reviewCount, {
              'count': service.reviewCount,
            }),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricItem(
            icon: Icons.schedule_rounded,
            iconColor: AppColors.primary,
            value: _durationLabel(context, service.durationMinutes),
            label: context.tr(LanguageKeys.estimatedTime),
          ),
        ),
      ],
    );
  }
}

final class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 21),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _AboutService extends StatelessWidget {
  const _AboutService({required this.service});

  final ServiceItem service;

  @override
  Widget build(BuildContext context) => _ContentCard(
    title: context.tr(LanguageKeys.aboutThisService),
    icon: Icons.description_outlined,
    child: Text(
      service.description,
      style: const TextStyle(color: AppColors.textSecondary, height: 1.6),
    ),
  );
}

final class _ServiceInclusions extends StatelessWidget {
  const _ServiceInclusions({required this.service});

  final ServiceItem service;

  @override
  Widget build(BuildContext context) => _ContentCard(
    title: context.tr(LanguageKeys.whatYouGet),
    icon: Icons.fact_check_outlined,
    child: Column(
      children: service.includes.indexed.map((entry) {
        final (index, item) = entry;
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == service.includes.length - 1 ? 0 : 13,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.success,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(item, style: const TextStyle(height: 1.45))),
            ],
          ),
        );
      }).toList(),
    ),
  );
}

final class _ContentCard extends StatelessWidget {
  const _ContentCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEDEBFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 21),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        child,
      ],
    ),
  );
}

final class _TrustCard extends StatelessWidget {
  const _TrustCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: const Color(0xFFF0FDF9),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFBDEDE2)),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.verified_user_outlined,
          color: AppColors.secondary,
          size: 28,
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(LanguageKeys.trustedService),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                context.tr(LanguageKeys.trustedServiceDescription),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _SimilarServicesSection extends StatelessWidget {
  const _SimilarServicesSection({required this.service});

  final ServiceItem service;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServiceCatalogCubit, ServiceCatalogState>(
      builder: (context, state) {
        if (state.isLoading) return const _SimilarServicesLoading();

        final similarServices = state.services
            .where(
              (item) =>
                  item.id != service.id &&
                  item.categoryId == service.categoryId,
            )
            .take(5)
            .toList();

        if (similarServices.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(LanguageKeys.similarServices),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr(LanguageKeys.similarServicesDescription),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(
                    Uri(
                      path: '/services',
                      queryParameters: {'category': service.category},
                    ).toString(),
                  ),
                  child: Text(context.tr(LanguageKeys.seeAll)),
                ),
              ],
            ),
            const SizedBox(height: 13),
            SizedBox(
              height: 248,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: similarServices.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _SimilarServiceCard(
                  service: similarServices[index],
                  onTap: () =>
                      context.push('/services/${similarServices[index].id}'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

final class _SimilarServiceCard extends StatelessWidget {
  const _SimilarServiceCard({required this.service, required this.onTap});

  final ServiceItem service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 224,
    child: Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(21),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 108,
                child: ServiceImage(
                  imageUrl: service.imageUrl,
                  fallbackIcon: service.icon,
                  color: service.color,
                  iconSize: 42,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              const SizedBox(height: 11),
              Text(
                service.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                service.shortDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  height: 1.3,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppFormatters.rupiah(service.price),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFF59E0B),
                    size: 16,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    service.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

final class _SimilarServicesLoading extends StatelessWidget {
  const _SimilarServicesLoading();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 180,
        height: 22,
        decoration: BoxDecoration(
          color: const Color(0xFFE8E8F0),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      const SizedBox(height: 13),
      SizedBox(
        height: 220,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 2,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, _) => Container(
            width: 224,
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8F0),
              borderRadius: BorderRadius.circular(21),
            ),
          ),
        ),
      ),
    ],
  );
}

final class _BookingBar extends StatelessWidget {
  const _BookingBar({required this.service});

  final ServiceItem service;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(20, 13, 20, 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
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
                  context.tr(LanguageKeys.startingPrice),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppFormatters.rupiah(service.price),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: FilledButton(
              onPressed: () => context.push('/services/${service.id}/book'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                context.tr(LanguageKeys.bookNow),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
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
