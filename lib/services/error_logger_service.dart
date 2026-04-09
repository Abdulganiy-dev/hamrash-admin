import 'dart:developer' as developer;

class ErrorLoggerService {
  static final Set<String> _sensitiveKeys = {
    'password',
    'pin',
    'token',
    'secret',
    'authorization',
    'auth',
    'apikey',
    'api_key',
    'accesstoken',
    'access_token',
    'refreshtoken',
    'refresh_token',
    'cardnumber',
    'card_number',
    'cvv',
    'cvc',
    'ssn',
    'otp',
    'sessionid',
    'session_id',
    'privatekey',
    'private_key',
    'credential',
    'credentials',
    'accountnumber',
    'account_number',
    'bvn',
    'nin',
    'phonenumber',
    'phone_number',
    'email',
  };

  static Map<String, dynamic> _sanitizeParams(Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) {
      return {};
    }

    final sanitized = <String, dynamic>{};

    for (final entry in params.entries) {
      final keyLower = entry.key.toLowerCase().replaceAll('_', '');

      final isSensitive = _sensitiveKeys.any((sensitiveKey) =>
        keyLower.contains(sensitiveKey.toLowerCase())
      );

      if (isSensitive) {
        sanitized[entry.key] = '[REDACTED]';
      } else {
        if (entry.value is Map<String, dynamic>) {
          sanitized[entry.key] = _sanitizeParams(entry.value as Map<String, dynamic>);
        }
        else if (entry.value is List) {
          sanitized[entry.key] = _sanitizeList(entry.value as List);
        } else {
          sanitized[entry.key] = entry.value;
        }
      }
    }

    return sanitized;
  }

  static List<dynamic> _sanitizeList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map<String, dynamic>) {
        return _sanitizeParams(item);
      } else if (item is List) {
        return _sanitizeList(item);
      }
      return item;
    }).toList();
  }

  static Future<void> logError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    bool fatal = false,
    Map<String, dynamic>? customParams,
  }) async {
    try {
      final sanitizedParams = _sanitizeParams(customParams);

      final errorMessage = context != null
          ? '[$context] $error'
          : error.toString();

      final logMessage = sanitizedParams.isNotEmpty
          ? '$errorMessage\nCustom params: $sanitizedParams'
          : errorMessage;

      developer.log(
        logMessage,
        name: 'ErrorLogger',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    } catch (loggingError) {
      developer.log(
        'Failed to log error: $loggingError\nOriginal error: $error',
        name: 'ErrorLogger',
        level: 1000,
      );
    }
  }

  static Future<void> logWarning(
    String message, {
    String? context,
    Map<String, dynamic>? customParams,
  }) async {
    try {
      final sanitizedParams = _sanitizeParams(customParams);

      final warningMessage = context != null
          ? '[$context] $message'
          : message;

      final logMessage = sanitizedParams.isNotEmpty
          ? '$warningMessage\nCustom params: $sanitizedParams'
          : warningMessage;

      developer.log(
        logMessage,
        name: 'ErrorLogger',
        level: 900,
      );
    } catch (loggingError) {
      developer.log(
        'Failed to log warning: $loggingError',
        name: 'ErrorLogger',
        level: 900,
      );
    }
  }

  static Future<void> logInfo(
    String message, {
    String? context,
  }) async {
    try {
      final infoMessage = context != null
          ? '[$context] $message'
          : message;

      developer.log(
        infoMessage,
        name: 'ErrorLogger',
        level: 800,
      );
    } catch (loggingError) {
      developer.log(
        'Failed to log info: $loggingError',
        name: 'ErrorLogger',
        level: 800,
      );
    }
  }

  static Future<void> logCaughtException(
    dynamic error,
    StackTrace stackTrace, {
    String? additionalContext,
  }) async {
    String? context;
    try {
      final stackLines = stackTrace.toString().split('\n');
      if (stackLines.isNotEmpty) {
        final firstLine = stackLines.first.trim();
        context = firstLine;
      }
    } catch (_) {
      context = additionalContext;
    }

    await logError(
      error,
      stackTrace: stackTrace,
      context: context ?? additionalContext,
      fatal: false,
    );
  }

  static Future<void> logNetworkError(
    dynamic error, {
    String? endpoint,
    String? method,
    int? statusCode,
    StackTrace? stackTrace,
  }) async {
    final customParams = <String, dynamic>{};

    if (endpoint != null) customParams['endpoint'] = endpoint;
    if (method != null) customParams['http_method'] = method;
    if (statusCode != null) customParams['status_code'] = statusCode;

    await logError(
      error,
      stackTrace: stackTrace,
      context: 'NetworkError',
      customParams: customParams,
    );
  }

  static Future<void> logDatabaseError(
    dynamic error, {
    String? operation,
    String? tableName,
    StackTrace? stackTrace,
  }) async {
    final customParams = <String, dynamic>{};

    if (operation != null) customParams['db_operation'] = operation;
    if (tableName != null) customParams['table_name'] = tableName;

    await logError(
      error,
      stackTrace: stackTrace,
      context: 'DatabaseError',
      customParams: customParams,
    );
  }
}

