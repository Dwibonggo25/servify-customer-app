import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/session/app_session_controller.dart';
import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../../libraries/design_system/widgets/app_bottom_navigation.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../services/presentation/cubit/service_category_cubit.dart';
import '../../../services/presentation/cubit/service_category_state.dart';
import '../widgets/service_card.dart';

final class HomePage extends StatelessWidget {
  const HomePage({required this.sessionController, super.key});

  final AppSessionController sessionController;

  @override
  Widget build(BuildContext context) {
    final user = sessionController.currentUser;
    final displayName = user?.fullName?.trim();

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthSubmissionStatus.success) {
          context.go('/login');
        } else if (state.status == AuthSubmissionStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message ?? context.tr(LanguageKeys.logoutFailed),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: _HomeAppBar(
          displayName: displayName,
          onNotificationsPressed: () => context.push('/notifications'),
          onAddressesPressed: () => context.push('/profile/addresses'),
          onLogoutPressed: () {
            context.read<AuthBloc>().add(const SignOutRequested());
          },
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            TextField(
              readOnly: true,
              onTap: () => context.push('/services?focusSearch=true'),
              decoration: InputDecoration(
                hintText: context.tr(LanguageKeys.searchService),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  tooltip: context.tr(LanguageKeys.serviceCategories),
                  onPressed: () => context.push('/services'),
                  icon: const Icon(Icons.tune_rounded),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _AiAssistantCard(onTap: () => context.push('/ai-assistant')),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(LanguageKeys.easierBooking),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr(LanguageKeys.easierBookingDescription),
                          style: const TextStyle(
                            color: Color(0xFFE7E5FF),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.rocket_launch_rounded,
                    color: Colors.white,
                    size: 56,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr(LanguageKeys.serviceCategories),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                TextButton(
                  onPressed: () => context.push('/services'),
                  child: Text(context.tr(LanguageKeys.seeAll)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BlocBuilder<ServiceCategoryCubit, ServiceCategoryState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const SizedBox(
                    height: 190,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (state.status == ServiceCategoryStatus.failure) {
                  return _CategoryLoadError(
                    onRetry: () => context.read<ServiceCategoryCubit>().load(),
                  );
                }
                if (state.categories.isEmpty) {
                  return const _EmptyCategories();
                }

                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.94,
                  children: state.categories.take(4).map((category) {
                    final uri = Uri(
                      path: '/services',
                      queryParameters: {'category': category.name},
                    );
                    return ServiceCard(
                      title: category.name,
                      subtitle: context.tr(
                        LanguageKeys.trustedCategoryService,
                        {'category': category.name.toLowerCase()},
                      ),
                      icon: category.icon,
                      color: category.color,
                      onTap: () => context.push(uri.toString()),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: AppBottomNavigation(
          selectedIndex: 0,
          onScanPressed: () =>
              _showComingSoon(context, context.tr(LanguageKeys.scanComingSoon)),
          onDestinationSelected: (index) {
            if (index == 0) return;
            if (index == 1) {
              context.go('/orders');
              return;
            }
            if (index == 2) {
              context.go('/favorites');
              return;
            }
            if (index == 3) {
              context.go('/profile');
              return;
            }
            final labels = [
              context.tr(LanguageKeys.home),
              context.tr(LanguageKeys.orders),
              context.tr(LanguageKeys.favorites),
              context.tr(LanguageKeys.profile),
            ];
            _showComingSoon(
              context,
              context.tr(LanguageKeys.pageComingSoon, {'page': labels[index]}),
            );
          },
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

final class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeAppBar({
    required this.displayName,
    required this.onNotificationsPressed,
    required this.onAddressesPressed,
    required this.onLogoutPressed,
  });

  final String? displayName;
  final VoidCallback onNotificationsPressed;
  final VoidCallback onAddressesPressed;
  final VoidCallback onLogoutPressed;

  @override
  Size get preferredSize => const Size.fromHeight(88);

  @override
  Widget build(BuildContext context) {
    final resolvedName = displayName?.isNotEmpty == true
        ? displayName!
        : context.tr(LanguageKeys.customer);
    final avatarLabel = resolvedName.characters.first.toUpperCase();

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: preferredSize.height,
      titleSpacing: 20,
      backgroundColor: const Color(0xFFFBFBFE),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: const Border(
        bottom: BorderSide(color: AppColors.border, width: 0.8),
      ),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEBFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(LanguageKeys.greeting, {'name': resolvedName}),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.tr(LanguageKeys.homeQuestion),
                  maxLines: 1,
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
      actions: [
        _HomeAppBarAction(
          tooltip: context.tr(LanguageKeys.notifications),
          icon: Icons.notifications_none_rounded,
          onPressed: onNotificationsPressed,
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          tooltip: context.tr(LanguageKeys.profile),
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onSelected: (value) {
            if (value == 'addresses') onAddressesPressed();
            if (value == 'logout') onLogoutPressed();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'addresses',
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(context.tr(LanguageKeys.addressManagement)),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    context.tr(LanguageKeys.logout),
                    style: const TextStyle(color: AppColors.error),
                  ),
                ],
              ),
            ),
          ],
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.16),
              ),
            ),
            child: Text(
              avatarLabel,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}

final class _HomeAppBarAction extends StatelessWidget {
  const _HomeAppBarAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
      ),
    ),
  );
}

final class _AiAssistantCard extends StatelessWidget {
  const _AiAssistantCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF3F0FF),
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      key: const Key('open_ai_assistant'),
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(LanguageKeys.askServifyAi),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.tr(LanguageKeys.aiHomeDescription),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 18),
          ],
        ),
      ),
    ),
  );
}

final class _CategoryLoadError extends StatelessWidget {
  const _CategoryLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(context.tr(LanguageKeys.categoryLoadFailed)),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.tr(LanguageKeys.retry)),
          ),
        ],
      ),
    );
  }
}

final class _EmptyCategories extends StatelessWidget {
  const _EmptyCategories();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        context.tr(LanguageKeys.categoryEmpty),
        textAlign: TextAlign.center,
      ),
    );
  }
}
