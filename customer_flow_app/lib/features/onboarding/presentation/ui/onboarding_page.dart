import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/session/app_session_controller.dart';
import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../../libraries/design_system/widgets/app_button.dart';
import '../bloc/onboarding_cubit.dart';

final class OnboardingPage extends StatefulWidget {
  const OnboardingPage({required this.sessionController, super.key});

  final AppSessionController sessionController;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

final class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();

  static const _items = [
    _OnboardingItem(
      icon: Icons.search_rounded,
      titleKey: LanguageKeys.onboardingFindTitle,
      descriptionKey: LanguageKeys.onboardingFindDescription,
    ),
    _OnboardingItem(
      icon: Icons.calendar_month_rounded,
      titleKey: LanguageKeys.onboardingBookTitle,
      descriptionKey: LanguageKeys.onboardingBookDescription,
    ),
    _OnboardingItem(
      icon: Icons.track_changes_rounded,
      titleKey: LanguageKeys.onboardingTrackTitle,
      descriptionKey: LanguageKeys.onboardingTrackDescription,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await widget.sessionController.completeOnboarding();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(),
      child: Builder(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _finish,
                      child: Text(context.tr(LanguageKeys.skip)),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _items.length,
                      onPageChanged: context
                          .read<OnboardingCubit>()
                          .pageChanged,
                      itemBuilder: (context, index) =>
                          _OnboardingSlide(item: _items[index]),
                    ),
                  ),
                  BlocBuilder<OnboardingCubit, int>(
                    builder: (context, currentPage) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _items.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: index == currentPage ? 28 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: index == currentPage
                                ? AppColors.primary
                                : AppColors.border,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  BlocBuilder<OnboardingCubit, int>(
                    builder: (context, currentPage) {
                      final isLast = currentPage == _items.length - 1;
                      return AppButton(
                        label: context.tr(
                          isLast ? LanguageKeys.startNow : LanguageKeys.next,
                        ),
                        icon: isLast ? Icons.arrow_forward_rounded : null,
                        onPressed: () {
                          if (isLast) {
                            _finish();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        },
                      );
                    },
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

final class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.item});

  final _OnboardingItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 220,
          height: 220,
          decoration: const BoxDecoration(
            color: Color(0xFFEDEBFF),
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, size: 96, color: AppColors.primary),
        ),
        const SizedBox(height: 48),
        Text(
          context.tr(item.titleKey),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        Text(
          context.tr(item.descriptionKey),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

final class _OnboardingItem {
  const _OnboardingItem({
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
  });

  final IconData icon;
  final String titleKey;
  final String descriptionKey;
}
