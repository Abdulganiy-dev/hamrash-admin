abstract class Env {
  String get baseUrl;

  Duration get connectTimeout;
  Duration get readTimeout;

  bool get enableVerboseLogs;

  String get clerkPublishableKey;
  String get supabaseUrl;
  String get supabaseAnonKey;
  String get clerkRedirectUrl;
  String get clerkDeepLinkUrl;

  /// Cloudflare API (user token or global key). Prefer `--dart-define` for secrets.
  String get cloudflareEmail;

  String get cloudflareApiToken;

  String get cloudflareAccountId;
}

class DevEnv implements Env {
  @override
  String get baseUrl => '';

  @override
  Duration get connectTimeout => const Duration(seconds: 10);

  @override
  Duration get readTimeout => const Duration(seconds: 15);

  @override
  bool get enableVerboseLogs => true;

  @override
  String get clerkPublishableKey =>
      'pk_test_bWVhc3VyZWQtZWdyZXQtNTEuY2xlcmsuYWNjb3VudHMuZGV2JA';

  @override
  String get supabaseUrl => 'https://zdamkdkebucubgzllwqx.supabase.co';

  @override
  String get supabaseAnonKey =>
      'sb_publishable_yFTws6io4lUcDpogxNe_vA_OWsPtJwS';

  @override
  String get clerkRedirectUrl =>
      'https://frank-dassie-81.clerk.accounts.dev';

  @override
  String get clerkDeepLinkUrl => '';

  /// Optional for user API tokens (`cfut_`); required with a Global API key.
  @override
  String get cloudflareEmail => const String.fromEnvironment(
        'CLOUDFLARE_EMAIL',
        defaultValue: 'hamrashinternationalsch@gmail.com',
      );

  /// Never commit a real token. Pass at build/run time, for example:
  /// `flutter run --dart-define=CLOUDFLARE_API_TOKEN=your_token`
  @override
  String get cloudflareApiToken => const String.fromEnvironment(
        'CLOUDFLARE_API_TOKEN',
      );

  @override
  String get cloudflareAccountId => const String.fromEnvironment(
        'CLOUDFLARE_ACCOUNT_ID',
        defaultValue: '82f79f2db37322491b27f7e8b0c0275d',
      );
}

class ProdEnv implements Env {
  @override
  String get baseUrl => '';

  @override
  Duration get connectTimeout => const Duration(seconds: 15);

  @override
  Duration get readTimeout => const Duration(seconds: 20);

  @override
  bool get enableVerboseLogs => false;

  @override
  String get clerkPublishableKey => ''; // TODO: Add production Clerk key

  @override
  String get supabaseUrl => ''; // TODO: Add production Supabase URL

  @override
  String get supabaseAnonKey => ''; // TODO: Add production Supabase anon key

  @override
  String get clerkRedirectUrl => ''; // TODO: Add production Clerk redirect URL

  @override
  String get clerkDeepLinkUrl => 'artisanpassport://auth/callback';

  @override
  String get cloudflareEmail => const String.fromEnvironment(
        'CLOUDFLARE_EMAIL',
      );

  @override
  String get cloudflareApiToken => const String.fromEnvironment(
        'CLOUDFLARE_API_TOKEN',
      );

  @override
  String get cloudflareAccountId => const String.fromEnvironment(
        'CLOUDFLARE_ACCOUNT_ID',
      );
}


