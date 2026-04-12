/// Error response model for Cloudflare API
class CloudflareErrorResponse {
  final List<CloudflareErrorItem> errors;

  CloudflareErrorResponse({required this.errors});

  factory CloudflareErrorResponse.fromJson(Map<String, dynamic> json) {
    final errorsList = json['errors'] as List<dynamic>? ?? [];
    final errors = errorsList
        .map((e) => CloudflareErrorItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return CloudflareErrorResponse(errors: errors);
  }

  Map<String, dynamic> toJson() {
    return {
      'errors': errors.map((e) => e.toJson()).toList(),
    };
  }

  /// Gets the first error message, or a default message
  String getErrorMessage() {
    if (errors.isNotEmpty && errors[0].message != null) {
      return errors[0].message!;
    }
    return 'Unknown Cloudflare error';
  }
}

/// Individual error item in Cloudflare error response
class CloudflareErrorItem {
  final String? message;
  final int? code;

  CloudflareErrorItem({this.message, this.code});

  factory CloudflareErrorItem.fromJson(Map<String, dynamic> json) {
    return CloudflareErrorItem(
      message: json['message']?.toString(),
      code: json['code'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (message != null) 'message': message,
      if (code != null) 'code': code,
    };
  }
}

