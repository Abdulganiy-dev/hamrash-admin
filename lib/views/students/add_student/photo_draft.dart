import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:hamrash_admin/api/models/students/student_registration.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/media_kind.dart';
import 'package:hamrash_admin/core/widgets/app_photo_field.dart';

/// One optional photo in the wizard (the student's, or a new parent's): the
/// picked bytes for the preview, and the Cloudflare image once uploaded.
///
/// The view model starts and finishes uploads; [generation] goes up on every
/// pick or removal, so an upload that finishes after it was replaced is known
/// to be an orphan and deleted.
class PhotoDraft {
  PhotoDraft(this.kind);

  final MediaKind kind;

  AppPhotoStatus status = AppPhotoStatus.empty;
  Uint8List? bytes;

  /// Where the picked file sits on the device, for list pictures.
  String? path;
  RegistrationPhoto? uploaded;

  /// Why the last upload failed, in words for the field.
  String? failure;

  /// The upload in flight, if any. Completes when it settles either way.
  Future<void>? pending;
  int generation = 0;

  bool get isEmpty => status == AppPhotoStatus.empty;
  bool get isUploading => status == AppPhotoStatus.uploading;
  bool get hasFailed => status == AppPhotoStatus.failed;
  bool get isAdded => status == AppPhotoStatus.added;

  /// What the field shows.
  ImageProvider? get preview => bytes == null ? null : MemoryImage(bytes!);

  /// The uploaded image, only once it is safely on Cloudflare.
  RegistrationPhoto? get ready => isAdded ? uploaded : null;

  void reset() {
    status = AppPhotoStatus.empty;
    bytes = null;
    path = null;
    uploaded = null;
    failure = null;
    pending = null;
    generation++;
  }
}
