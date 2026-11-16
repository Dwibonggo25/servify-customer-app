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
  const ServiceListPage({
    this.initialCategory,
    this.autofocusSearch = false,
    super.key,
  });

  final String? initialCategory;
  final bool autofocusSearch;

  @override
  State<ServiceListPage> createState() => _ServiceListPageState();
}

final class _ServiceListPageState extends State<ServiceListPage> {
  static const _allCategory = '__all__';

  final _searchController = TextEditingController();
  String _query = '';
  late String _category;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory ?? _allCategory;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _refresh() => Future.wait([
    context.read<ServiceCatalogCubit>().load(),
    context.read<ServiceCategoryCubit>().load(),
  ]);

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _category = _allCategory;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      appBar: const _ServiceAppBar(),
      body: BlocBuilder<ServiceCatalogCubit, ServiceCatalogState>(
        builder: (context, serviceState) {
          if (serviceState.isLoading) return const _ServiceListLoading();
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
              final hasFilters =
                  _query.trim().isNotEmpty || selectedCategory != _allCategory;

              return RefreshIndicator(
                onRefresh: _refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _ServiceDiscoverySection(
                        controller: _searchController,
                        autofocusSearch: widget.autofocusSearch,
                        query: _query,
                        onQueryChanged: (value) =>
                            setState(() => _query = value),
                        onClearQuery: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        categoryFilters: _CategoryFilters(
                          state: categoryState,
                          categories: categories,
                          selectedCategory: selectedCategory,
                          onSelected: (category) =>
                              setState(() => _category = category),
                          onRetry: () =>
                              context.read<ServiceCategoryCubit>().load(),
                        ),
                      ),
                    ),
                    if (services.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _ServiceResultHeader(count: services.length),
                      ),
                    if (services.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyServiceState(
                          hasFilters: hasFilters,
                          onClearFilters: _clearFilters,
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
                        sliver: SliverList.separated(
                          itemCount: services.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}

final class _ServiceAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ServiceAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(96);

  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    toolbarHeight: preferredSize.height,
    backgroundColor: const Color(0xFFFBFBFE),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleSpacing: 8,
    leadingWidth: 68,
    shape: const Border(
      bottom: BorderSide(color: AppColors.border, width: 0.8),
    ),
    leading: Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Center(
        child: Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.maybePop(context),
            child: const SizedBox(
              width: 42,
              height: 42,
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    ),
    title: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEDEBFF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.home_repair_service_outlined,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(LanguageKeys.serviceList),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                context.tr(LanguageKeys.servicePageSubtitle),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _ServiceDiscoverySection extends StatelessWidget {
  const _ServiceDiscoverySection({
    required this.controller,
    required this.autofocusSearch,
    required this.query,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.categoryFilters,
  });

  final TextEditingController controller;
  final bool autofocusSearch;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final Widget categoryFilters;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A191A2C),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EFFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(LanguageKeys.findService),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr(LanguageKeys.findServiceDescription),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: controller,
            autofocus: autofocusSearch,
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: context.tr(LanguageKeys.searchService),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: context.tr(LanguageKeys.clearSearch),
                      onPressed: onClearQuery,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: const Color(0xFFF8F8FC),
            ),
          ),
          const SizedBox(height: 16),
          categoryFilters,
        ],
      ),
    );
  }
}

final class _ServiceResultHeader extends StatelessWidget {
  const _ServiceResultHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.tr(LanguageKeys.serviceResults),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEDEBFF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              context.tr(LanguageKeys.serviceResultCount, {
                'count': count.toString(),
              }),
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEDED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  color: AppColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.tr(LanguageKeys.reloadServices)),
              ),
            ],
          ),
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
        child: Row(
          children: [
            _CategorySkeleton(width: 72),
            SizedBox(width: 8),
            _CategorySkeleton(width: 104),
            SizedBox(width: 8),
            _CategorySkeleton(width: 88),
          ],
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
          final selected = category == selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: selected
                  ? const Icon(Icons.check_rounded, size: 17)
                  : null,
              label: Text(
                category == _ServiceListPageState._allCategory
                    ? context.tr(LanguageKeys.all)
                    : category,
              ),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) => onSelected(category),
            ),
          );
        }).toList(),
      ),
    );
  }
}

final class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 38,
    decoration: BoxDecoration(
      color: const Color(0xFFEDEDF4),
      borderRadius: BorderRadius.circular(999),
    ),
  );
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF20213A).withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 132,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 104,
                    height: 132,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ServiceImage(
                            imageUrl: service.imageUrl,
                            fallbackIcon: service.icon,
                            color: service.color,
                            iconSize: 38,
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xD9232435),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFBBF24),
                                  size: 14,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  service.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 13),
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
                                    color: const Color(0xFFEDEBFF),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    service.category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _FavoriteButton(
                              isFavorite: isFavorite,
                              onPressed: onFavoriteToggle,
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          service.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service.shortDescription,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                            height: 1.28,
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
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Container(
                              width: 29,
                              height: 29,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onPressed});

  final bool isFavorite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.tr(
        isFavorite ? LanguageKeys.removeFavorite : LanguageKeys.addFavorite,
      ),
      child: Material(
        color: isFavorite ? const Color(0xFFFFEDEF) : const Color(0xFFF5F5F9),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 34,
            child: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: isFavorite ? AppColors.error : AppColors.textSecondary,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

final class _EmptyServiceState extends StatelessWidget {
  const _EmptyServiceState({
    required this.hasFilters,
    required this.onClearFilters,
  });

  final bool hasFilters;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 8, 32, 56),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Color(0xFFEDEBFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr(LanguageKeys.serviceNotFound),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              context.tr(LanguageKeys.serviceNotFoundDescription),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: Text(context.tr(LanguageKeys.clearFilters)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _ServiceListLoading extends StatefulWidget {
  const _ServiceListLoading();

  @override
  State<_ServiceListLoading> createState() => _ServiceListLoadingState();
}

final class _ServiceListLoadingState extends State<_ServiceListLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final color = Color.lerp(
          const Color(0xFFE7E7EF),
          const Color(0xFFF5F5F9),
          _controller.value,
        )!;
        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          children: [
            _LoadingPanel(color: color),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _LoadingBlock(color: color, width: 112, height: 20),
                _LoadingBlock(color: color, width: 58, height: 26),
              ],
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < 4; index++) ...[
              _LoadingServiceCard(color: color),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

final class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LoadingBlock(color: color, width: 210, height: 20),
          const SizedBox(height: 9),
          _LoadingBlock(color: color, width: 270, height: 13),
          const SizedBox(height: 20),
          _LoadingBlock(color: color, width: double.infinity, height: 54),
          const SizedBox(height: 16),
          Row(
            children: [
              _LoadingBlock(color: color, width: 70, height: 38),
              const SizedBox(width: 8),
              _LoadingBlock(color: color, width: 100, height: 38),
              const SizedBox(width: 8),
              _LoadingBlock(color: color, width: 82, height: 38),
            ],
          ),
        ],
      ),
    );
  }
}

final class _LoadingServiceCard extends StatelessWidget {
  const _LoadingServiceCard({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 146,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _LoadingBlock(color: color, width: 94, height: 116, radius: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LoadingBlock(color: color, width: 74, height: 12),
                const SizedBox(height: 9),
                _LoadingBlock(color: color, width: 152, height: 17),
                const SizedBox(height: 9),
                _LoadingBlock(color: color, width: double.infinity, height: 12),
                const SizedBox(height: 6),
                _LoadingBlock(color: color, width: 128, height: 12),
                const SizedBox(height: 12),
                _LoadingBlock(color: color, width: 96, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({
    required this.color,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final Color color;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}
