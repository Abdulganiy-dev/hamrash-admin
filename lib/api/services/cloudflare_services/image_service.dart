import 'dart:typed_data';

import 'package:hamrash_admin/api/services/cloudflare_services/media_kind.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/media_upload_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';

/// Uploads images to Cloudflare Images.
///
/// ```dart
/// final logo = await locator<ImageService>().uploadImage(
///   bytes,
///   'logo.jpg',
///   kind: MediaKind.schoolLogo,
/// );
/// // save logo.id as organizations.logo_id and logo.url as logo_url
/// ```
class ImageService {
  final MediaUploadService _uploads = locator<MediaUploadService>();

  /// [filename] keeps its extension; one without an extension becomes `.png`.
  Future<UploadedMedia> uploadImage(
    Uint8List imageData,
    String filename, {
    required MediaKind kind,
  }) {
    return _uploads.upload(
      isVideo: false,
      bytes: imageData,
      filename: filename.contains('.') ? filename : '$filename.png',
      kind: kind,
    );
  }
}
