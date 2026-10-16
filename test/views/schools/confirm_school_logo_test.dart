import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/cloudflare_models/cloudflare_errors.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/image_service.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/media_kind.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/media_upload_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/school_service.dart';
import 'package:hamrash_admin/views/schools/confirm_school/confirm_school_view_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Organization _kings({String? logoId, String? logoUrl}) => Organization(
  id: 'kings',
  code: 'HMR-000001',
  name: 'Kings College',
  status: OrganizationStatus.trial,
  createdBy: 'platform',
  numberPrefix: 'KCL',
  logoId: logoId,
  logoUrl: logoUrl,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

class _Picker extends ImagePicker {
  _Picker({this.picks = true});

  final bool picks;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async => picks
      ? XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'pick.png')
      : null;
}

class _Images implements ImageService {
  _Images({this.failWith});

  final Object? failWith;
  Uint8List? bytes;
  String? filename;
  MediaKind? kind;

  @override
  Future<UploadedMedia> uploadImage(
    Uint8List imageData,
    String filename, {
    required MediaKind kind,
  }) async {
    if (failWith != null) throw failWith!;
    bytes = imageData;
    this.filename = filename;
    this.kind = kind;
    return const UploadedMedia(
      id: 'hamrash-admin/dev/school-logos/uuid-1',
      url:
          'https://imagedelivery.net/hash/hamrash-admin/dev/school-logos/uuid-1/public',
    );
  }

  @override
  Future<void> deleteImage(String id) async {}
}

class _Schools extends SchoolService {
  _Schools()
    : super(SupabaseClient('https://example.supabase.co', 'test-key'));

  Map<String, Object?>? saved;

  @override
  Future<Organization> updateDetails(
    String organizationId,
    Map<String, Object?> changes,
  ) async {
    saved = changes;
    return _kings(
      logoId: changes['logo_id'] as String?,
      logoUrl: changes['logo_url'] as String?,
    );
  }
}

void main() {
  // The "Logo added" toast asks Flutter for the widget tree.
  TestWidgetsFlutterBinding.ensureInitialized();

  ConfirmSchoolViewModel model(
    _Schools schools,
    _Images images, {
    ImagePicker? picker,
  }) => ConfirmSchoolViewModel(
    organization: _kings(),
    firstName: null,
    onConfirmed: (_) {},
    service: schools,
    imageService: images,
    imagePicker: picker ?? _Picker(),
  );

  test('the logo goes through the upload function and is saved on the school', () async {
    final schools = _Schools();
    final images = _Images();
    final vm = model(schools, images);

    await vm.changeLogo();

    expect(images.kind, MediaKind.schoolLogo);
    expect(images.bytes, [1, 2, 3]);
    expect(images.filename, 'school-logo-kings');
    expect(schools.saved, {
      'logo_id': 'hamrash-admin/dev/school-logos/uuid-1',
      'logo_url':
          'https://imagedelivery.net/hash/hamrash-admin/dev/school-logos/uuid-1/public',
    });
    expect(vm.organization.logoId, 'hamrash-admin/dev/school-logos/uuid-1');
    expect(vm.uploadingLogo, isFalse);
  });

  test('nothing is uploaded or saved when no picture is picked', () async {
    final schools = _Schools();
    final images = _Images();
    await model(schools, images, picker: _Picker(picks: false)).changeLogo();

    expect(images.bytes, isNull);
    expect(schools.saved, isNull);
  });

  test('a failed upload leaves the school alone and the button usable', () async {
    final schools = _Schools();
    final vm = model(
      schools,
      _Images(failWith: CloudflareException.httpError(502)),
    );

    await vm.changeLogo();

    expect(schools.saved, isNull);
    expect(vm.organization.logoId, isNull);
    expect(vm.uploadingLogo, isFalse);
  });
}
