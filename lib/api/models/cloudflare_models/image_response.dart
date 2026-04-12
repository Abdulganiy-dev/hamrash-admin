
import 'package:hamrash_admin/api/api_setup/from_json.dart';

/// Response model for Cloudflare Images API
class ImageResponse implements FromJson<ImageResponse> {
  String? id;
  String? filename;
  Map<String, dynamic>? meta;
  String? uploaded;
  bool? requireSignedURLs;
  List<String>? variants;
  bool? success;
  List<dynamic>? errors;
  List<dynamic>? messages;

  ImageResponse({
    this.id,
    this.filename,
    this.meta,
    this.uploaded,
    this.requireSignedURLs,
    this.variants,
    this.success,
    this.errors,
    this.messages,
  });

  @override
  ImageResponse fromJson(Map<String, dynamic> json) {
    if (json['result'] != null) {
      final result = json['result'] as Map<String, dynamic>;
      id = result['id']?.toString();
      filename = result['filename']?.toString();
      meta = result['meta'] as Map<String, dynamic>?;
      uploaded = result['uploaded']?.toString();
      requireSignedURLs = result['requireSignedURLs'] as bool?;
      variants = (result['variants'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList();
    }
    success = json['success'] as bool?;
    errors = json['errors'] as List<dynamic>?;
    messages = json['messages'] as List<dynamic>?;
    return this;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    final Map<String, dynamic> result = <String, dynamic>{};
    if (id != null) result['id'] = id;
    if (filename != null) result['filename'] = filename;
    if (meta != null) result['meta'] = meta;
    if (uploaded != null) result['uploaded'] = uploaded;
    if (requireSignedURLs != null) {
      result['requireSignedURLs'] = requireSignedURLs;
    }
    if (variants != null) result['variants'] = variants;
    data['result'] = result;
    if (success != null) data['success'] = success;
    if (errors != null) data['errors'] = errors;
    if (messages != null) data['messages'] = messages;
    return data;
  }
}

