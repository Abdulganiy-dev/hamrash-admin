/// What went wrong while uploading media.
enum CloudflareError {
  /// No answer at all: offline, timeout or a dropped connection.
  noHTTPResponse,

  /// The `media-upload` function or Cloudflare answered with an error status.
  httpError,

  /// The `media-upload` function's answer wasn't what we expect.
  unableToParse,
}

/// Thrown by `MediaUploadService` (and so by `ImageService` and
/// `VideoService`). [friendlyError] turns it into a sentence for the user.
class CloudflareException implements Exception {
  const CloudflareException({required this.type, this.message, this.statusCode});

  final CloudflareError type;
  final String? message;

  /// The HTTP status for [CloudflareError.httpError]: 401 means the sign-in
  /// wasn't accepted, 400 means the app or kind isn't on the function's
  /// allow-list, 502 means Cloudflare refused.
  final int? statusCode;

  factory CloudflareException.noHTTPResponse() => const CloudflareException(
    type: CloudflareError.noHTTPResponse,
    message: 'No HTTP response received',
  );

  factory CloudflareException.httpError(int statusCode) => CloudflareException(
    type: CloudflareError.httpError,
    message: 'HTTP error: $statusCode',
    statusCode: statusCode,
  );

  factory CloudflareException.unableToParse() => const CloudflareException(
    type: CloudflareError.unableToParse,
    message: 'Unable to parse response',
  );

  @override
  String toString() => 'CloudflareException: ${message ?? type.name}';
}
