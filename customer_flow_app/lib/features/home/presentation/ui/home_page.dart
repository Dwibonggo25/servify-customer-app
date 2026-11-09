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
        appBar: AppBar(
          title: Text(context.tr(LanguageKeys.home)),
          actions: [
            IconButton(
              tooltip: context.tr(LanguageKeys.notifications),
              onPressed: () => context.push('/notifications'),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') {
                  context.read<AuthBloc>().add(const SignOutRequested());
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'logout',
                  child: Text(context.tr(LanguageKeys.logout)),
                ),
              ],
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CircleAvatar(
                  backgroundColor: Color(0xFFEDEBFF),
                  child: Icon(Icons.person_rounded, color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              context.tr(LanguageKeys.greeting, {
                'name': displayName?.isNotEmpty == true
                    ? displayName!
                    : context.tr(LanguageKeys.customer),
              }),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(LanguageKeys.homeQuestion),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                hintText: context.tr(LanguageKeys.searchService),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.tune_rounded),
                ),
              ),
            ),
            const SizedBox(height: 24),
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
