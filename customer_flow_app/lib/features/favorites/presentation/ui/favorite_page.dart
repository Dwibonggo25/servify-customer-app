import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../libraries/core/formatters/app_formatters.dart';
import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(context.tr(LanguageKeys.favorites)),
      ),
      body: BlocBuilder<FavoriteCubit, FavoriteState>(
        builder: (context, favoriteState) {
          return BlocBuilder<ServiceCatalogCubit, ServiceCatalogState>(
            builder: (context, catalogState) => _body(
              context,
              favoriteState: favoriteState,
              catalogState: catalogState,
            ),
          );
        },
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
  }

  Widget _body(
    BuildContext context, {
    required FavoriteState favoriteState,
    required ServiceCatalogState catalogState,
  }) {
    if (favoriteState.isLoading || catalogState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (catalogState.status == ServiceCatalogStatus.failure) {
      return _LoadError(
        message:
            catalogState.message ?? context.tr(LanguageKeys.serviceLoadFailed),
        onRetry: () {
          context.read<FavoriteCubit>().load();
          context.read<ServiceCatalogCubit>().load();
        },
      );
    }

    final favorites = catalogState.services
        .where((service) => favoriteState.contains(service.id))
        .toList(growable: false);
    if (favorites.isEmpty) return const _EmptyFavoriteState();

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          context.read<FavoriteCubit>().load(),
          context.read<ServiceCatalogCubit>().load(),
        ]);
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        itemCount: favorites.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _FavoriteServiceCard(
          service: favorites[index],
          onTap: () => context.push('/services/${favorites[index].id}'),
          onRemove: () =>
              context.read<FavoriteCubit>().toggle(favorites[index].id),
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
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: ServiceImage(
                imageUrl: service.imageUrl,
                fallbackIcon: service.icon,
                color: service.color,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    service.shortDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppFormatters.rupiah(service.price),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: context.tr(LanguageKeys.removeFavorite),
              onPressed: onRemove,
              color: AppColors.error,
              icon: const Icon(Icons.favorite_rounded),
            ),
          ],
        ),
      ),
    ),
  );
}

final class _EmptyFavoriteState extends StatelessWidget {
  const _EmptyFavoriteState();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              size: 42,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            context.tr(LanguageKeys.favoriteEmptyTitle),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(LanguageKeys.favoriteEmptyDescription),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.push('/services'),
            icon: const Icon(Icons.search_rounded),
            label: Text(context.tr(LanguageKeys.exploreServices)),
          ),
        ],
      ),
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
