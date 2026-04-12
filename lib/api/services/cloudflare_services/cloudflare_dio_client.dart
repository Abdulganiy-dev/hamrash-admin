import 'package:dio/dio.dart';
import 'package:hamrash_admin/api/models/cloudflare_models/cloudflare_secrets.dart';

/// Dio client specifically for Cloudflare API calls
class CloudflareDioClient {
  final Dio _dio;

  CloudflareDioClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'https://api.cloudflare.com/client/v4',
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );

  /// User API tokens (`cfut_` / `cfuu_`) use Bearer auth. Global API keys use
  /// `X-Auth-Email` + `X-Auth-Key`. See Cloudflare API fundamentals.
  Map<String, String> _authHeaders(CloudflareSecrets secrets) {
    final token = secrets.apiToken;
    if (token == null || token.isEmpty) {
      return {};
    }
    final isUserApiToken =
        token.startsWith('cfut_') || token.startsWith('cfuu_');
    if (isUserApiToken) {
      return {'Authorization': 'Bearer $token'};
    }
    final email = secrets.email;
    if (email != null && email.isNotEmpty) {
      return {
        'X-Auth-Email': email,
        'X-Auth-Key': token,
      };
    }
    return {'Authorization': 'Bearer $token'};
  }

  /// Uploads an image to Cloudflare Images
  Future<Response> uploadImage({
    required String accountId,
    required FormData formData,
    required CloudflareSecrets secrets,
  }) async {
    return await _dio.post(
      '/accounts/$accountId/images/v1',
      data: formData,
      options: Options(headers: _authHeaders(secrets)),
    );
  }

  /// Deletes an image from Cloudflare Images
  Future<Response> deleteImage({
    required String accountId,
    required String imageId,
    required CloudflareSecrets secrets,
  }) async {
    return await _dio.delete(
      '/accounts/$accountId/images/v1/$imageId',
      options: Options(headers: _authHeaders(secrets)),
    );
  }

  /// Uploads a video to Cloudflare Stream
  Future<Response> uploadVideo({
    required String accountId,
    required FormData formData,
    required CloudflareSecrets secrets,
  }) async {
    return await _dio.post(
      '/accounts/$accountId/stream',
      data: formData,
      options: Options(headers: _authHeaders(secrets)),
    );
  }

  /// Deletes a video from Cloudflare Stream
  Future<Response> deleteVideo({
    required String accountId,
    required String videoId,
    required CloudflareSecrets secrets,
  }) async {
    return await _dio.delete(
      '/accounts/$accountId/stream/$videoId',
      options: Options(headers: _authHeaders(secrets)),
    );
  }
}

