import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../libraries/core/formatters/app_formatters.dart';
import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../../libraries/design_system/widgets/app_bar.dart';
import '../../../../libraries/design_system/widgets/app_bottom_navigation.dart';
import '../../../services/domain/entities/service_item.dart';
import '../../../services/presentation/cubit/service_catalog_cubit.dart';
import '../../../services/presentation/cubit/service_catalog_state.dart';
import '../../../services/presentation/widgets/service_image.dart';
import '../cubit/favorite_cubit.dart';
import '../cubit/favorite_state.dart';

final class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F8FC),
    appBar: AppBarWidget(
      title: LanguageKeys.favorites,
      icons: Icons.favorite_rounded,
      subtitle: LanguageKeys.favoritePageSubtitle,
    ),
    body: BlocBuilder<FavoriteCubit, FavoriteState>(
      builder: (context, favoriteState) =>
          BlocBuilder<ServiceCatalogCubit, ServiceCatalogState>(
            builder: (context, catalogState) => _body(
              context,
              favoriteState: favoriteState,
              catalogState: catalogState,
            ),
          ),
    ),
    bottomNavigationBar: AppBottomNavigation(
      selectedIndex: 2,
      onScanPressed: () =>
          _message(context, context.tr(LanguageKeys.scanComingSoon)),
      onDestinationSelected: (index) {
        if (index == 0) context.go('/home');
        if (index == 1) context.go('/orders');
        if (index == 3) context.go('/profile');
      },
    ),
  );

  Widget _body(
    BuildContext context, {
    required FavoriteState favoriteState,
    required ServiceCatalogState catalogState,
  }) {
    if ((favoriteState.isLoading && favoriteState.serviceIds.isEmpty) ||
        (catalogState.isLoading && catalogState.services.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }
    if (catalogState.status == ServiceCatalogStatus.failure ||
        (favoriteState.status == FavoriteStatus.failure &&
            favoriteState.serviceIds.isEmpty)) {
      return _LoadError(
        message:
            catalogState.message ??
            favoriteState.message ??
            context.tr(LanguageKeys.serviceLoadFailed),
        onRetry: () => _reload(context),
      );
    }

    final favorites = catalogState.services
        .where((service) => favoriteState.contains(service.id))
        .toList(growable: false);

    return RefreshIndicator(
      onRefresh: () => _reload(context),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 34),
        children: [
          if (favoriteState.status == FavoriteStatus.failure) ...[
            _SyncErrorBanner(
              message:
                  favoriteState.message ??
                  context.tr(LanguageKeys.generalError),
            ),
            const SizedBox(height: 14),
          ],
          _FavoriteSummary(
            count: favorites.length,
            onExplore: () => context.push('/services'),
          ),
          const SizedBox(height: 25),
          _SectionTitle(
            title: context.tr(LanguageKeys.favoriteCollection),
            subtitle: context.tr(LanguageKeys.favoriteCollectionDescription),
          ),
          const SizedBox(height: 14),
          if (favorites.isEmpty)
            const _EmptyFavoriteCard()
          else
            ...favorites.map(
              (service) => _FavoriteServiceCard(
                service: service,
                onTap: () => context.push('/services/${service.id}'),
                onRemove: () => _removeFavorite(context, service),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _reload(BuildContext context) {
    return Future.wait([
      context.read<FavoriteCubit>().load(),
      context.read<ServiceCatalogCubit>().load(),
    ]);
  }

  Future<void> _removeFavorite(
    BuildContext context,
    ServiceItem service,
  ) async {
    final cubit = context.read<FavoriteCubit>();
    await cubit.toggle(service.id);
    if (!context.mounted || cubit.state.contains(service.id)) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            context.tr(LanguageKeys.favoriteRemoved, {'name': service.name}),
          ),
          action: SnackBarAction(
            label: context.tr(LanguageKeys.undo),
            onPressed: () => cubit.toggle(service.id),
          ),
        ),
      );
  }

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

final class _FavoriteSummary extends StatelessWidget {
  const _FavoriteSummary({required this.count, required this.onExplore});

  final int count;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(23),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.07),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFFCE7F3),
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Icon(
            Icons.bookmark_added_rounded,
            color: Color(0xFFDB2777),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(LanguageKeys.favoriteSavedCount, {
                  'count': '$count',
                }),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr(LanguageKeys.favoritePageSubtitle),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: context.tr(LanguageKeys.exploreServices),
          onPressed: onExplore,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            foregroundColor: AppColors.primary,
          ),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    ),
  );
}

final class _FavoriteServiceCard extends StatelessWidget {
  const _FavoriteServiceCard({
    required this.service,
    required this.onTap,
    required this.onRemove,
  });

  final ServiceItem service;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 94,
                height: 118,
                child: ServiceImage(
                  imageUrl: service.imageUrl,
                  fallbackIcon: service.icon,
                  color: service.color,
                  iconSize: 38,
                  borderRadius: BorderRadius.circular(19),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: service.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                service.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: service.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: context.tr(LanguageKeys.removeFavorite),
                          onPressed: onRemove,
                          color: const Color(0xFFE11D48),
                          icon: const Icon(Icons.favorite_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      service.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      service.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFF59E0B),
                          size: 17,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            context.tr(LanguageKeys.reviewsAndEstimate, {
                              'reviews':
                                  '${service.rating.toStringAsFixed(1)} (${service.reviewCount})',
                              'duration': context.tr(LanguageKeys.minute, {
                                'count': '${service.durationMinutes}',
                              }),
                            }),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      context.tr(LanguageKeys.startingAt, {
                        'price': AppFormatters.rupiah(service.price),
                      }),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

final class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    ],
  );
}

final class _EmptyFavoriteCard extends StatelessWidget {
  const _EmptyFavoriteCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(26, 30, 26, 28),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: const BoxDecoration(
            color: Color(0xFFFCE7F3),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.favorite_border_rounded,
            size: 40,
            color: Color(0xFFDB2777),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          context.tr(LanguageKeys.favoriteEmptyTitle),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 7),
        Text(
          context.tr(LanguageKeys.favoriteEmptyDescription),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => context.push('/services'),
          icon: const Icon(Icons.search_rounded),
          label: Text(context.tr(LanguageKeys.exploreServices)),
        ),
      ],
    ),
  );
}

final class _SyncErrorBanner extends StatelessWidget {
  const _SyncErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppColors.error.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(Icons.sync_problem_rounded, color: AppColors.error),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
}

final class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 52,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.tr(LanguageKeys.retry)),
          ),
        ],
      ),
    ),
  );
}
