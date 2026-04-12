import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hamrash_admin/api/models/cloudflare_models/cloudflare_secrets.dart';
import 'package:hamrash_admin/env_config/flavor_config.dart';

class SecretService {
  static const String _storageKey = 'cloudflare_secrets';

  final FlutterSecureStorage _secureStorage;

  SecretService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Returns Cloudflare credentials from [FlavorConfig] / [Env] when
  /// [CloudflareSecrets.hasAccountAndToken] is satisfied; otherwise reads
  /// secure storage.
  Future<CloudflareSecrets> getSecrets() async {
    final flavor = FlavorConfig.instance;
    if (flavor != null) {
      final fromEnv = CloudflareSecrets.fromEnv(flavor.envConfig());
      if (fromEnv.hasAccountAndToken) {
        return fromEnv;
      }
    }

    final raw = await _secureStorage.read(key: _storageKey);
    if (raw == null || raw.isEmpty) {
      return CloudflareSecrets();
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return CloudflareSecrets().fromJson(map);
    } catch (_) {
      return CloudflareSecrets();
    }
  }

  /// Persists credentials to the platform keystore (Keychain / EncryptedSharedPreferences).
  Future<void> saveSecrets(CloudflareSecrets secrets) async {
    await _secureStorage.write(
      key: _storageKey,
      value: jsonEncode(secrets.toJson()),
    );
  }

  Future<void> clearSecrets() async {
    await _secureStorage.delete(key: _storageKey);
  }
}