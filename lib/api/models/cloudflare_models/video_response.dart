
import 'package:hamrash_admin/api/api_setup/from_json.dart';

/// Response model for Cloudflare Stream API
class VideoResponse implements FromJson<VideoResponse> {
  String? uid;
  String? thumbnail;
  bool? readyToStream;
  Map<String, dynamic>? status;
  Map<String, dynamic>? meta;
  Map<String, dynamic>? playback;
  bool? success;
  List<dynamic>? errors;
  List<dynamic>? messages;

  VideoResponse({
    this.uid,
    this.thumbnail,
    this.readyToStream,
    this.status,
    this.meta,
    this.playback,
    this.success,
    this.errors,
    this.messages,
  });

  @override
  VideoResponse fromJson(Map<String, dynamic> json) {
    if (json['result'] != null) {
      final result = json['result'] as Map<String, dynamic>;
      uid = result['uid']?.toString();
      thumbnail = result['thumbnail']?.toString();
      readyToStream = result['readyToStream'] as bool?;
      status = result['status'] as Map<String, dynamic>?;
      meta = result['meta'] as Map<String, dynamic>?;
      playback = result['playback'] as Map<String, dynamic>?;
    }
    success = json['success'] as bool?;
    errors = json['errors'] as List<dynamic>?;
    messages = json['messages'] as List<dynamic>?;
    return this;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    final Map<String, dynamic> result = <String, dynamic>{};
    if (uid != null) result['uid'] = uid;
    if (thumbnail != null) result['thumbnail'] = thumbnail;
    if (readyToStream != null) result['readyToStream'] = readyToStream;
    if (status != null) result['status'] = status;
    if (meta != null) result['meta'] = meta;
    if (playback != null) result['playback'] = playback;
    data['result'] = result;
    if (success != null) data['success'] = success;
    if (errors != null) data['errors'] = errors;
    if (messages != null) data['messages'] = messages;
    return data;
  }
}

