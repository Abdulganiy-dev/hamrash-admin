import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hamrash_admin/api/services/api_route.dart';

import '../../env_config/flavor_config.dart';
import '../../resources/app_logger.dart';

import 'api_response.dart';
import 'auth_interceptor.dart';
import 'from_json.dart';
import 'log_interceptor.dart';

/// Base interface for API clients
abstract class BaseAPIClient {
  Future<ResponseWrapper<T>> request<T extends FromJson>({
    required APIRouteConfigurable route,
    required Create<T> create,
    dynamic data,
    int? timeoutInMilliseconds,
    Map<String, String>? headers,
  });
}

/// Main API client that wraps Dio and handles route-based requests
class APIClient implements BaseAPIClient {
  final BaseOptions options;
  final bool isCard;
  late Dio instance;

  APIClient(this.options, {this.isCard = false}) {
    instance = Dio(options);
    instance.options.listFormat = ListFormat.multi;
    
    // Ensure JSON responses are parsed automatically
    instance.options.responseType = ResponseType.json;

    // Add auth interceptor first (so it runs before logging)
    instance.interceptors.add(AuthInterceptor());
    instance.interceptors.add(APILogInterceptor());
  }

  @override
  Future<ResponseWrapper<T>> request<T extends FromJson>({
    required APIRouteConfigurable route,
    required Create<T> create,
    dynamic data,
    int? timeoutInMilliseconds,
    Map<String, String>? headers,
  }) async {
    final config = route.getConfig();
    if (config == null) {
      throw ErrorResponse(message: 'Failed to load request options.');
    }

    // Set device type header
    config.headers["X-App-Device-Type"] = Platform.operatingSystem
        .toLowerCase();

    final (version, buildNumber) = await _getAppVersion();
    config.headers["X-App-Ver"] = "$version:$buildNumber";

    if (headers != null) {
      config.headers.clear();
      config.headers.addAll(headers);
    }

    config.baseUrl = options.baseUrl;

    if (data != null) {
      if (config.method == ApiMethod.get) {
        if (config.path.contains('all-rrr') && data['email'] != null) {
          final String queryString = _buildQueryString(data);
          config.path = "${config.path}?$queryString";
        } else {
          config.queryParameters = data;
        }
      } else {
        config.data = data;
      }
    }

    try {
      final response = await instance
          .fetch(config)
          .timeout(
            Duration(
              milliseconds:
                  timeoutInMilliseconds ??
                  FlavorConfig.instance!.values.readTimeout.inMilliseconds,
            ),
          );

    
      dynamic responseData = response.data;
      if (responseData is String) {
        try {
          responseData = jsonDecode(responseData);
        } catch (e) {
          AppLogger.error('Failed to parse JSON response', error: e);
          return ResponseWrapper.onError(
            create: create,
            data: {
              "status": "50",
              "message": "Invalid response format",
            },
          );
        }
      }

      final wrapper = ResponseWrapper<T>(create: create);
      final ResponseWrapper<T> parsedData = await wrapper.initialiseData(
        responseData,
      );
      return parsedData;
    } on TimeoutException catch (e) {
      AppLogger.error('API timeout', error: e);
      return ResponseWrapper.onError(
        create: create,
        data: {
          "status": "50",
          "message": "An error occurred, please try again later",
        },
      );
    } on DioException catch (e) {
      AppLogger.error('Dio error', error: e);
      if (e.error is SocketException) {
        return ResponseWrapper.onError(
          create: create,
          data: {"status": "50", "message": "${e.message}"},
        );
      } else {
        return ResponseWrapper.onError(
          create: create,
          data: {
            "status": "50",
            "message": "An error occurred, please try again later",
          },
        );
      }
    } catch (e) {
      AppLogger.error('API error', error: e);
      return ResponseWrapper.onError(
        create: create,
        data: {
          "status": "50",
          "message": "An error occurred, please try again later",
        },
      );
    }
  }

 
  Future<(String, String)> _getAppVersion() async {
    return ('1.0.0', '1');
  }


  String _buildQueryString(Map<String, dynamic> params) {
    final List<String> queryParts = [];

    params.forEach((key, value) {
      if (value != null) {
        if (key == 'email') {
          queryParts.add('$key=$value');
        } else {
          queryParts.add('$key=${Uri.encodeComponent(value.toString())}');
        }
      }
    });

    return queryParts.join('&');
  }
}
