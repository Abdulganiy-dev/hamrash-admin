import 'package:dio/dio.dart';

import '../../env_config/flavor_config.dart';
import 'log_interceptor.dart';

/// Singleton factory that creates and caches Dio instances per base URL
class DioClientFactory {
  static final DioClientFactory _instance = DioClientFactory._internal();
  factory DioClientFactory() => _instance;
  DioClientFactory._internal();

  static DioClientFactory get instance => _instance;

  final Map<String, Dio> _clients = {};

  /// Gets or creates a Dio client for the given base URL
  Dio getClient({
    required String baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
  }) {
    if (_clients.containsKey(baseUrl)) {
      return _clients[baseUrl]!;
    }

    final env = FlavorConfig.instance?.envConfig();
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout ?? env?.connectTimeout ?? const Duration(seconds: 10),
        receiveTimeout: receiveTimeout ?? env?.readTimeout ?? const Duration(seconds: 15),
      ),
    );

    // Add logging interceptor (only in debug mode)
    dio.interceptors.add(APILogInterceptor());

    _clients[baseUrl] = dio;
    return dio;
  }

  /// Gets a Dio client configured for the main API
  Dio getMainApiClient() {
    final env = FlavorConfig.instance?.envConfig();
    if (env == null) {
      throw Exception('FlavorConfig not initialized');
    }
    return getClient(baseUrl: env.baseUrl);
  }

  /// Gets a Dio client for analytics API (if configured)
  Dio? getAnalyticsClient() {
    // Uncomment and configure if you have analyticsBaseUrl in Env
    // final env = FlavorConfig.instance?.envConfig();
    // if (env is DevEnv || env is ProdEnv) {
    //   return getClient(baseUrl: env.analyticsBaseUrl);
    // }
    return null;
  }

  /// Clears all cached clients (useful for testing)
  void clearClients() {
    _clients.clear();
  }
}

