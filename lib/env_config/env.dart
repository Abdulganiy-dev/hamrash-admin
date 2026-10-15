/// Environment values per flavor. Only publishable keys live here. Cloudflare
/// credentials are not in the app at all: they're secrets on the `media-upload`
/// Supabase edge function (see `supabase/functions/`).
abstract class Env {
  String get baseUrl;

  Duration get connectTimeout;
  Duration get readTimeout;

  bool get enableVerboseLogs;

  String get clerkPublishableKey;
  String get supabaseUrl;
  String get supabasePublishableKey;
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
      'pk_test_c29saWQtc3RpbmdyYXktNzY3Ni5jbGVyay5hY2NvdW50cy5kZXYk';

  @override
  String get supabaseUrl => 'https://ccvyhbyrtobdsecqvhcr.supabase.co';

  @override
  String get supabasePublishableKey =>
      'sb_publishable_rsWnj5Dj89nS_AOcZk9Yfw_ucYGtrec';
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
  String get supabasePublishableKey => ''; // TODO: Add production Supabase publishable key
}
