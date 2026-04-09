import 'package:clerk_auth/clerk_auth.dart' as clerk_auth;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:dio/dio.dart';

import '../../resources/utils/view_util.dart';
import '../../services/error_logger_service.dart';

/// Interceptor that adds Clerk authentication token to requests
/// when the route has `extra: {'Authorize': true}`
class AuthInterceptor extends Interceptor {

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Check if this route requires authorization
    if (options.extra['Authorize'] == true) {
      try {
        await _addAuthToken(options);
      } catch (e, stackTrace) {
        ErrorLoggerService.logError(
          e,
          context: 'AuthInterceptor.onRequest',
          stackTrace: stackTrace,
        );
        // Continue with request even if token retrieval fails
        // The API will return an authentication error if token is missing
      }
    }
    handler.next(options);
  }

  /// Adds the Clerk session token to the request headers
  Future<void> _addAuthToken(RequestOptions options) async {
    try {
      // Get context from navigator key
      final context = ViewUtil.navigatorKey.currentContext;
      if (context == null) {
        ErrorLoggerService.logWarning(
          'Authorization required but no context available for: ${options.uri}',
          context: 'AuthInterceptor._addAuthToken',
        );
        return;
      }

      // Get the Clerk session token
      final clerkAuth = ClerkAuth.of(context);
      final session = clerkAuth.session;
      
      if (session != null) {
        // The session has a lastActiveToken property with a jwt field
        final clerk_auth.Session? sessionObj = session as clerk_auth.Session?;
        final token = sessionObj?.lastActiveToken?.jwt;
        
        if (token != null && token.isNotEmpty) {
          // Add Authorization header
          options.headers['Authorization'] = 'Bearer $token';
          ErrorLoggerService.logInfo(
            'Authorization token added to request: ${options.uri}',
            context: 'AuthInterceptor._addAuthToken',
          );
        } else {
          ErrorLoggerService.logWarning(
            'Authorization required but no token available for: ${options.uri}',
            context: 'AuthInterceptor._addAuthToken',
          );
        }
      } else {
        ErrorLoggerService.logWarning(
          'Authorization required but no active session for: ${options.uri}',
          context: 'AuthInterceptor._addAuthToken',
        );
      }
    } catch (e, stackTrace) {
      ErrorLoggerService.logError(
        e,
        context: 'AuthInterceptor._addAuthToken',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

