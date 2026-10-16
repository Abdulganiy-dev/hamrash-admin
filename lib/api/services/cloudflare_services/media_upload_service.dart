import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:hamrash_admin/api/models/cloudflare_models/cloudflare_errors.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/media_kind.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;

/// A file that now lives on Cloudflare.
class UploadedMedia {
  const UploadedMedia({required this.id, required this.url});

  /// Cloudflare Images id, or the Stream uid for a video. Store it next to the
  /// URL (for a logo: `organizations.logo_id`) so the file can be found again.
  final String id;

  /// Where to show it: the image URL, or the video's HLS playlist.
  final String url;
}

/// Uploads and deletes images and videos on Cloudflare without the app ever
/// holding a Cloudflare credential. The `media-upload` Supabase edge function checks the
/// Clerk login, reserves a labelled one-time upload URL, and the file goes
/// straight to that URL. `media-delete` removes an image the caller uploaded.
///
/// This and [PlatformService] are the only code that talks to Supabase.
/// Screens never use this directly: they go through `ImageService` or
/// `VideoService`.
class MediaUploadService {
  MediaUploadService(this._supabase, {Dio? dio}) : _dio = dio ?? Dio();

  final SupabaseClient _supabase;
  final Dio _dio;

  /// Throws [CloudflareException]:
  /// * `httpError` with 401 (sign-in not accepted), 400 (app or kind not on the
  ///   allow-list), 502 (Cloudflare refused) or the status Cloudflare's upload
  ///   URL returned
  /// * `noHTTPResponse` when there's no connection
  /// * `unableToParse` when the function answers with something unexpected
  Future<UploadedMedia> upload({
    required bool isVideo,
    required Uint8List bytes,
    required String filename,
    required MediaKind kind,
  }) async {
    final Object? reservation;
    try {
      final response = await _supabase.functions.invoke(
        'media-upload',
        body: {
          'type': isVideo ? 'video' : 'image',
          'app': MediaKind.appName,
          'kind': kind.path,
        },
      );
      reservation = response.data;
    } on FunctionException catch (e) {
      throw _failure(e);
    } on Exception {
      throw CloudflareException.noHTTPResponse();
    }

    if (reservation is! Map) throw CloudflareException.unableToParse();
    final uploadUrl = reservation['uploadURL'];
    final id = reservation['id'];
    final url = reservation['url'];
    if (uploadUrl is! String || id is! String || url is! String) {
      throw CloudflareException.unableToParse();
    }

    try {
      final result = await _dio.post<Object?>(
        uploadUrl,
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: filename),
        }),
      );
      final status = result.statusCode ?? 500;
      if (status < 200 || status >= 300) {
        throw CloudflareException.httpError(status);
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      throw status == null
          ? CloudflareException.noHTTPResponse()
          : CloudflareException.httpError(status);
    }
    return UploadedMedia(id: id, url: url);
  }

  /// Deletes an image by the [id] that [upload] returned. Only the person who
  /// uploaded it can delete it. An image that's already gone counts as deleted.
  ///
  /// Throws [CloudflareException]: `httpError` with 403 (not yours, or not
  /// uploaded through `media-upload`), 400 (not one of our ids), 401 or 502,
  /// and `noHTTPResponse` when there's no connection.
  Future<void> delete(String id) async {
    try {
      await _supabase.functions.invoke('media-delete', body: {'id': id});
    } on FunctionException catch (e) {
      if (_isAlreadyGone(e)) return;
      throw _failure(e);
    } on Exception {
      throw CloudflareException.noHTTPResponse();
    }
  }

  /// Newer Supabase versions report a request that never got an answer as a
  /// [FunctionException] with status 0; that isn't an HTTP error.
  static CloudflareException _failure(FunctionException e) => e.status == 0
      ? CloudflareException.noHTTPResponse()
      : CloudflareException.httpError(e.status);

  /// `media-delete` answers 404 `{"error": "not_found"}` for an image that no
  /// longer exists. A 404 with any other body is Supabase saying the function
  /// itself isn't there, which must not be mistaken for "already deleted".
  static bool _isAlreadyGone(FunctionException e) =>
      e.status == 404 &&
      e.details is Map &&
      (e.details as Map)['error'] == 'not_found';
}
