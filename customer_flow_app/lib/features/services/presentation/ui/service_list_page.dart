import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../libraries/core/formatters/app_formatters.dart';
import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../favorites/presentation/cubit/favorite_cubit.dart';
import '../../../favorites/presentation/cubit/favorite_state.dart';
import '../../domain/entities/service_item.dart';
import '../cubit/service_catalog_cubit.dart';
import '../cubit/service_catalog_state.dart';
import '../cubit/service_category_cubit.dart';
import '../cubit/service_category_state.dart';
import '../widgets/service_image.dart';

final class ServiceListPage extends StatefulWidget {
  const ServiceListPage({this.initialCategory, super.key});

  final String? initialCategory;

  @override
  State<ServiceListPage> createState() => _ServiceListPageState();
}

final class _ServiceListPageState extends State<ServiceListPage> {
  static const _allCategory = '__all__';
  String _query = '';
  late String _category;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory ?? _allCategory;
  }

  List<ServiceItem> _filteredServices(
    List<ServiceItem> services,
    String category,
  ) {
    final normalizedQuery = _query.trim().toLowerCase();
    return services.where((service) {
      final matchesCategory =
          category == _allCategory || service.category == category;
      final matchesQuery =
          normalizedQuery.isEmpty ||
          service.name.toLowerCase().contains(normalizedQuery) ||
          service.shortDescription.toLowerCase().contains(normalizedQuery);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr(LanguageKeys.serviceList))),
      body: BlocBuilder<ServiceCatalogCubit, ServiceCatalogState>(
        builder: (context, serviceState) {
          if (serviceState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (serviceState.status == ServiceCatalogStatus.failure) {
            return _ServiceLoadError(
              message:
                  serviceState.message ??
                  context.tr(LanguageKeys.serviceLoadFailed),
              onRetry: () => context.read<ServiceCatalogCubit>().load(),
            );
          }

          return BlocBuilder<ServiceCategoryCubit, ServiceCategoryState>(
            builder: (context, categoryState) {
              final categories = [
                _allCategory,
                ...categoryState.categories.map((category) => category.name),
              ];
              final selectedCategory = categories.contains(_category)
                  ? _category
                  : _allCategory;
              final services = _filteredServices(
                serviceState.services,
                selectedCategory,
              );

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(LanguageKeys.findService),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr(LanguageKeys.findServiceDescription),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            onChanged: (value) =>
                                setState(() => _query = value),
                            decoration: InputDecoration(
                              hintText: context.tr(LanguageKeys.searchService),
                              prefixIcon: const Icon(Icons.search_rounded),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _CategoryFilters(
                            state: categoryState,
                            categories: categories,
                            selectedCategory: selectedCategory,
                            onSelected: (category) =>
                                setState(() => _category = category),
                            onRetry: () =>
                                context.read<ServiceCategoryCubit>().load(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (services.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyServiceState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      sliver: SliverList.separated(
                        itemCount: services.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final service = services[index];
                          return BlocBuilder<FavoriteCubit, FavoriteState>(
                            buildWhen: (previous, current) =>
                                previous.contains(service.id) !=
                                current.contains(service.id),
                            builder: (context, favoriteState) =>
                                _ServiceListTile(
                                  service: service,
                                  isFavorite: favoriteState.contains(
                                    service.id,
                                  ),
                                  onFavoriteToggle: () => context
                                      .read<FavoriteCubit>()
                                      .toggle(service.id),
                                  onTap: () =>
                                      context.push('/services/${service.id}'),
                                ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

final class _ServiceLoadError extends StatelessWidget {
  const _ServiceLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
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
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr(LanguageKeys.reloadServices)),
            ),
          ],
        ),
      ),
    );
  }
}

final class _CategoryFilters extends StatelessWidget {
  const _CategoryFilters({
    required this.state,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
    required this.onRetry,
  });

  final ServiceCategoryState state;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const SizedBox(
        height: 40,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      );
    }
    if (state.status == ServiceCategoryStatus.failure) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(context.tr(LanguageKeys.reloadCategories)),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                category == _ServiceListPageState._allCategory
                    ? context.tr(LanguageKeys.all)
                    : category,
              ),
              selected: category == selectedCategory,
              onSelected: (_) => onSelected(category),
            ),
          );
        }).toList(),
      ),
    );
  }
}

final class _ServiceListTile extends StatelessWidget {
  const _ServiceListTile({
    required this.service,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onTap,
  });

  final ServiceItem service;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            service.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: context.tr(
                            isFavorite
                                ? LanguageKeys.removeFavorite
                                : LanguageKeys.addFavorite,
                          ),
                          onPressed: onFavoriteToggle,
                          color: AppColors.error,
                          icon: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                          ),
                        ),
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFF59E0B),
                          size: 18,
                        ),
                        Text(
                          service.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
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
                    const SizedBox(height: 10),
                    Text(
                      context.tr(LanguageKeys.startingAt, {
                        'price': AppFormatters.rupiah(service.price),
                      }),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _EmptyServiceState extends StatelessWidget {
  const _EmptyServiceState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 52,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(context.tr(LanguageKeys.serviceNotFound)),
          ],
        ),
      ),
    );
  }
}
