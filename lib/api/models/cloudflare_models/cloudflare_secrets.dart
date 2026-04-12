import 'package:hamrash_admin/api/api_setup/from_json.dart';
import 'package:hamrash_admin/env_config/env.dart';

class CloudflareSecrets implements FromJson<CloudflareSecrets> {
  String? email;
  String? apiToken;
  String? accountId;

  CloudflareSecrets({this.email, this.apiToken, this.accountId});

  /// Maps flavor [Env] values into this model (empty strings become null).
  CloudflareSecrets.fromEnv(Env env)
      : email = _trimToNull(env.cloudflareEmail),
        apiToken = _trimToNull(env.cloudflareApiToken),
        accountId = _trimToNull(env.cloudflareAccountId);

  static String? _trimToNull(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  /// Enough to call Cloudflare Images/Stream with a user API token.
  bool get hasAccountAndToken =>
      accountId != null &&
      accountId!.isNotEmpty &&
      apiToken != null &&
      apiToken!.isNotEmpty;

  @override
  CloudflareSecrets fromJson(Map<String, dynamic> json) {
    email = json['email'];
    apiToken = json['api_token'];
    accountId = json['account_id'];
    return this;
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'api_token': apiToken,
      'account_id': accountId,
    };
  }
}
