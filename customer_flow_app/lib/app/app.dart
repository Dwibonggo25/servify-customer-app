import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../libraries/core/localization/app_localizations.dart';
import '../libraries/core/localization/language_controller.dart';
import '../libraries/core/localization/language_keys.dart';
import '../libraries/design_system/theme/app_theme.dart';
import 'router/app_router.dart';

final class CustomerFlowApp extends StatefulWidget {
  const CustomerFlowApp({required this.appRouter, super.key});

  final AppRouter appRouter;

  @override
  State<CustomerFlowApp> createState() => _CustomerFlowAppState();
}

final class _CustomerFlowAppState extends State<CustomerFlowApp> {
  @override
  void dispose() {
    widget.appRouter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.instance,
      builder: (context, locale, _) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => context.tr(LanguageKeys.appName),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light,
        routerConfig: widget.appRouter.router,
      ),
    );
  }
}
