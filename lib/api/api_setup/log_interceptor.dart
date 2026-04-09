import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../env_config/flavor_config.dart';
import '../../services/error_logger_service.dart';

/// Secure logging interceptor that redacts sensitive fields
class APILogInterceptor extends InterceptorsWrapper {
  /// List of sensitive field names to redact
  static const List<String> _sensitiveFields = [
    'authorization',
    'token',
    'access_token',
    'refresh_token',
    'password',
    'pin',
    'otp',
    'secret',
    'bvn',
    'account_number',
    'card_number',
    'cvv',
    'cvv2',
    'security_code',
  ];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode && FlavorConfig.instance?.envConfig().enableVerboseLogs == true) {
      final sanitizedOptions = _sanitizeData(options.data);
      final headers = _sanitizeHeaders(options.headers);
      
      final message = StringBuffer();
      message.writeln('┌─────────────────────────────────────────────────────────');
      message.writeln('│ REQUEST: ${options.method} ${options.uri}');
      message.writeln('│ Headers: $headers');
      if (sanitizedOptions != null) {
        message.writeln('│ Data: $sanitizedOptions');
      }
      message.writeln('└─────────────────────────────────────────────────────────');
      
      ErrorLoggerService.logInfo(
        message.toString(),
        context: 'APILogInterceptor.onRequest',
      );
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode && FlavorConfig.instance?.envConfig().enableVerboseLogs == true) {
      final sanitizedData = _sanitizeData(response.data);
      
      final message = StringBuffer();
      message.writeln('┌─────────────────────────────────────────────────────────');
      message.writeln('│ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      message.writeln('│ Data: $sanitizedData');
      message.writeln('└─────────────────────────────────────────────────────────');
      
      ErrorLoggerService.logInfo(
        message.toString(),
        context: 'APILogInterceptor.onResponse',
      );
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode && FlavorConfig.instance?.envConfig().enableVerboseLogs == true) {
      final sanitizedResponse = err.response != null 
          ? _sanitizeData(err.response?.data) 
          : null;
      
      ErrorLoggerService.logNetworkError(
        err,
        endpoint: err.requestOptions.uri.toString(),
        method: err.requestOptions.method,
        statusCode: err.response?.statusCode,
        stackTrace: err.stackTrace,
      );
      
      final message = StringBuffer();
      message.writeln('┌─────────────────────────────────────────────────────────');
      message.writeln('│ ERROR: ${err.type} ${err.requestOptions.uri}');
      message.writeln('│ Message: ${err.message}');
      if (err.response != null) {
        message.writeln('│ Status Code: ${err.response?.statusCode}');
        message.writeln('│ Response: $sanitizedResponse');
      }
      message.writeln('└─────────────────────────────────────────────────────────');
      
      ErrorLoggerService.logWarning(
        message.toString(),
        context: 'APILogInterceptor.onError',
      );
    }
    super.onError(err, handler);
  }

  /// Sanitizes data by redacting sensitive fields
  dynamic _sanitizeData(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      final sanitized = <String, dynamic>{};
      data.forEach((key, value) {
        final keyStr = key.toString().toLowerCase();
        if (_sensitiveFields.any((field) => keyStr.contains(field))) {
          sanitized[key] = '***REDACTED***';
        } else if (value is Map) {
          sanitized[key] = _sanitizeData(value);
        } else if (value is List) {
          sanitized[key] = value.map((item) => _sanitizeData(item)).toList();
        } else {
          sanitized[key] = value;
        }
      });
      return sanitized;
    }

    if (data is List) {
      return data.map((item) => _sanitizeData(item)).toList();
    }

    return data;
  }

  /// Sanitizes headers by redacting sensitive fields
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = <String, dynamic>{};
    headers.forEach((key, value) {
      final keyStr = key.toString().toLowerCase();
      if (_sensitiveFields.any((field) => keyStr.contains(field))) {
        sanitized[key] = '***REDACTED***';
      } else {
        sanitized[key] = value;
      }
    });
    return sanitized;
  }
}

