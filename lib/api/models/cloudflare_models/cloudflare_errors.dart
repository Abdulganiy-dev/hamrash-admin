/// Cloudflare-specific error types
enum CloudflareError {
  noHTTPResponse,
  cloudflareError,
  httpError,
  unableToParse,
  unableToRetrieveSecrets,
}

/// Custom exception for Cloudflare API errors
class CloudflareException implements Exception {
  final CloudflareError type;
  final String? message;
  final int? statusCode;

  CloudflareException({
    required this.type,
    this.message,
    this.statusCode,
  });

  /// Creates a CloudflareException for no HTTP response
  factory CloudflareException.noHTTPResponse() {
    return CloudflareException(
      type: CloudflareError.noHTTPResponse,
      message: 'No HTTP response received',
    );
  }

  /// Creates a CloudflareException for Cloudflare API errors
  factory CloudflareException.cloudflareError(String message) {
    return CloudflareException(
      type: CloudflareError.cloudflareError,
      message: message,
    );
  }

  /// Creates a CloudflareException for HTTP errors
  factory CloudflareException.httpError(int statusCode) {
    return CloudflareException(
      type: CloudflareError.httpError,
      message: 'HTTP error: $statusCode',
      statusCode: statusCode,
    );
  }

  /// Creates a CloudflareException for parsing errors
  factory CloudflareException.unableToParse() {
    return CloudflareException(
      type: CloudflareError.unableToParse,
      message: 'Unable to parse response',
    );
  }

  /// Creates a CloudflareException for secrets retrieval errors
  factory CloudflareException.unableToRetrieveSecrets() {
    return CloudflareException(
      type: CloudflareError.unableToRetrieveSecrets,
      message: 'Unable to retrieve Cloudflare secrets',
    );
  }

  @override
  String toString() {
    if (message != null) {
      return 'CloudflareException: $message';
    }
    return 'CloudflareException: ${type.name}';
  }
}

