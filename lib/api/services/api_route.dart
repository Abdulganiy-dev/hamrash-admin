import 'package:dio/dio.dart';

/// HTTP method constants
class ApiMethod {
  static const String get = 'GET';
  static const String post = 'POST';
  static const String put = 'PUT';
  static const String patch = 'PATCH';
  static const String delete = 'DELETE';
}

/// Interface for route configuration
abstract class APIRouteConfigurable {
  RequestOptions? getConfig();
}

/// Enum for all API endpoints
enum ApiType { admin }

/// Route wrapper that implements APIRouteConfigurable
class ApiRoute implements APIRouteConfigurable {
  final ApiType type;
  final String? routeParams; // For path params like /users/{id}
  final Map<String, dynamic>? data; // Request body/query params

  ApiRoute(this.type, {this.routeParams, this.data});

  @override
  RequestOptions? getConfig() {
    switch (type) {
      case ApiType.admin:
        return RequestOptions(
          path: '/admin',
          method: ApiMethod.get,
          extra: {'Authorize': true},
        );
    }
  }
}
