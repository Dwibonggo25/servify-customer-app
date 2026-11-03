import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/session/app_session_controller.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../../libraries/design_system/widgets/app_brand.dart';

final class SplashPage extends StatefulWidget {
  const SplashPage({required this.sessionController, super.key});

  final AppSessionController sessionController;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

final class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _continueToApp();
  }

  Future<void> _continueToApp() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) context.go(widget.sessionController.destinationAfterSplash);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F7FC), Color(0xFFE9F9F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 850),
                curve: Curves.easeOutBack,
                tween: Tween(begin: 0.65, end: 1),
                builder: (context, scale, child) => Transform.scale(
                  scale: scale,
                  child: Opacity(opacity: scale.clamp(0, 1), child: child),
                ),
                child: const AppBrand(),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
