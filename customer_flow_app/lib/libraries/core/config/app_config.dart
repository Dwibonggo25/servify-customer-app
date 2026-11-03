enum Flavor { dev, uat, prod }

final class AppConfig {
  AppConfig._({
    required this.flavor,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  final Flavor flavor;
  final String supabaseUrl;
  final String supabaseAnonKey;

  static late final AppConfig instance;

  static void initialize(Flavor flavor) {
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    if (supabaseUrl.isEmpty ||
        supabaseAnonKey.isEmpty ||
        supabaseUrl.contains('YOUR_PROJECT') ||
        supabaseAnonKey.contains('YOUR_SUPABASE')) {
      throw StateError(
        'Supabase belum dikonfigurasi untuk environment ${flavor.name}.',
      );
    }

    instance = AppConfig._(
      flavor: flavor,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
    );
  }
}
