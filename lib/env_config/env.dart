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
}


