import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:hamrash_admin/api/models/cloudflare_models/cloudflare_errors.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/secret_service.dart';

import '../../../api/models/cloudflare_models/cloudflare_error_response.dart';
import '../../../api/models/cloudflare_models/image_response.dart';
import '../../../singleton_locator/locator.dart';
import 'cloudflare_dio_client.dart';


/// Service for managing images on Cloudflare Images
class ImageService {
  final SecretService _secretsService = locator<SecretService>();
  final CloudflareDioClient _cloudflareClient = locator<CloudflareDioClient>();

  /// Uploads an image to Cloudflare Images
  Future<ImageResponse> uploadImage(
    Uint8List imageData,
    String filename, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Get secrets
      final secrets = await _secretsService.getSecrets();
      if (!secrets.hasAccountAndToken) {
        throw CloudflareException.unableToRetrieveSecrets();
      }

      // Build FormData
      final formData = FormData.fromMap({
        'requireSignedURLs': 'false',
        'file': MultipartFile.fromBytes(
          imageData,
          filename: '$filename.png',
        ),
        if (metadata != null)
          'metadata': jsonEncode(metadata),
      });

      // Make request
      final response = await _cloudflareClient.uploadImage(
        accountId: secrets.accountId!,
        formData: formData,
        secrets: secrets,
      );

      // Validate response
      if (response.statusCode != 200) {
        await _handleErrorResponse(response);
      }

      // Parse response
      if (response.data is Map<String, dynamic>) {
        final imageResponse = ImageResponse().fromJson(
          response.data as Map<String, dynamic>,
        );
        
        // Check if Cloudflare returned an error
        if (imageResponse.success == false && imageResponse.errors != null) {
          final errorResponse = CloudflareErrorResponse.fromJson(
            response.data as Map<String, dynamic>,
          );
          throw CloudflareException.cloudflareError(
            errorResponse.getErrorMessage(),
          );
        }
        
        return imageResponse;
      }

      throw CloudflareException.unableToParse();
    } on CloudflareException {
      rethrow;
    } on DioException catch (e) {
      if (e.response != null) {
        await _handleErrorResponse(e.response!);
      }
      throw CloudflareException.noHTTPResponse();
    } catch (e) {
      if (e is CloudflareException) {
        rethrow;
      }
      throw CloudflareException.unableToParse();
    }
  }

  /// Deletes an image from Cloudflare Images
  Future<void> deleteImage(String imageId) async {
    try {
      // Get secrets
      final secrets = await _secretsService.getSecrets();
      if (!secrets.hasAccountAndToken) {
        throw CloudflareException.unableToRetrieveSecrets();
      }

      // Make request
      final response = await _cloudflareClient.deleteImage(
        accountId: secrets.accountId!,
        imageId: imageId,
        secrets: secrets,
      );

      // Validate response
      if (response.statusCode != 200) {
        await _handleErrorResponse(response);
      }
    } on CloudflareException {
      rethrow;
    } on DioException catch (e) {
      if (e.response != null) {
        await _handleErrorResponse(e.response!);
      }
      throw CloudflareException.noHTTPResponse();
    } catch (e) {
      if (e is CloudflareException) {
        rethrow;
      }
      throw CloudflareException.httpError(e is int ? e : 500);
    }
  }

  /// Handles error responses from Cloudflare API
  Future<void> _handleErrorResponse(Response response) async {
    if (response.statusCode == null) {
      throw CloudflareException.noHTTPResponse();
    }

    if (response.statusCode != 200) {
      if (response.data is Map<String, dynamic>) {
        try {
          final errorResponse = CloudflareErrorResponse.fromJson(
            response.data as Map<String, dynamic>,
          );
          throw CloudflareException.cloudflareError(
            errorResponse.getErrorMessage(),
          );
        } catch (e) {
          if (e is CloudflareException) {
            rethrow;
          }
          throw CloudflareException.httpError(response.statusCode!);
        }
      } else {
        throw CloudflareException.httpError(response.statusCode!);
      }
    }
  }
}

