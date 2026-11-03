import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/data/repositories/supabase_auth_repository.dart';
import '../features/onboarding/data/repositories/hive_onboarding_repository.dart';
import '../features/profile/data/repositories/supabase_profile_repository.dart';
import '../features/services/data/repositories/supabase_service_category_repository.dart';
import '../libraries/core/config/app_config.dart';
import '../libraries/core/constants/app_constants.dart';
import '../libraries/core/localization/language_controller.dart';
import 'app.dart';
import 'router/app_router.dart';
import 'session/app_session_controller.dart';

Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    AppConfig.initialize(flavor);
  } on StateError catch (error) {
    runApp(ConfigurationRequiredApp(message: error.message));
    return;
  }

  await Hive.initFlutter();
  final settingsBox = await Hive.openBox<dynamic>(AppConstants.settingsBox);
  LanguageController.instance.initialize(settingsBox);

  await Supabase.initialize(
    url: AppConfig.instance.supabaseUrl,
    publishableKey: AppConfig.instance.supabaseAnonKey,
  );

  final authRepository = SupabaseAuthRepository(Supabase.instance.client);
  final profileRepository = SupabaseProfileRepository(Supabase.instance.client);
  final serviceCategoryRepository = SupabaseServiceCategoryRepository(
    Supabase.instance.client,
  );
  final onboardingRepository = HiveOnboardingRepository(settingsBox);
  final sessionController = AppSessionController(
    authRepository: authRepository,
    onboardingRepository: onboardingRepository,
  );
  final appRouter = AppRouter(
    sessionController: sessionController,
    authRepository: authRepository,
    profileRepository: profileRepository,
    serviceCategoryRepository: serviceCategoryRepository,
  );

  runApp(CustomerFlowApp(appRouter: appRouter));
}

final class ConfigurationRequiredApp extends StatelessWidget {
  const ConfigurationRequiredApp({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.settings_suggest_rounded, size: 48),
                        const SizedBox(height: 20),
                        Text(
                          'Konfigurasi Supabase diperlukan',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        Text(message),
                        const SizedBox(height: 20),
                        const Text(
                          'Isi SUPABASE_URL dan SUPABASE_ANON_KEY pada '
                          'config/dev.json, kemudian jalankan:',
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const SelectableText(
                            'flutter run --flavor dev '
                            '-t lib/app/launcher/main_dev.dart '
                            '--dart-define-from-file=config/dev.json',
                            style: TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
