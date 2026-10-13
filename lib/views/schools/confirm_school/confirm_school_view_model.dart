import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/image_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/school_service.dart';
import 'package:hamrash_admin/core/utils/validation_util.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';
import 'package:image_picker/image_picker.dart';

/// A detail on "Check your school" that can be edited in a sheet.
enum SchoolField {
  name('School name', 'name', 'Kings College'),
  address('Address', 'address', '14 Admiralty Way, Lekki, Lagos'),
  phone('Phone', 'phone', '08035550142'),
  email('Email', 'email', 'hello@kingscollege.ng'),
  numberPrefix('Number prefix', 'number_prefix', 'KCL');

  const SchoolField(this.label, this.column, this.hint);

  final String label;
  final String column;
  final String hint;

  bool get isRequired =>
      this == SchoolField.name || this == SchoolField.numberPrefix;

  TextInputType get keyboardType => switch (this) {
    SchoolField.phone => TextInputType.phone,
    SchoolField.email => TextInputType.emailAddress,
    SchoolField.address => TextInputType.streetAddress,
    _ => TextInputType.text,
  };

  TextCapitalization get capitalization => switch (this) {
    SchoolField.numberPrefix => TextCapitalization.characters,
    SchoolField.email => TextCapitalization.none,
    SchoolField.phone => TextCapitalization.none,
    _ => TextCapitalization.words,
  };

  String? helper(String value) => switch (this) {
    SchoolField.numberPrefix =>
      '2 to 8 letters or numbers. Admission numbers look like '
          '${value.isEmpty ? hint : value}/${DateTime.now().year}/0001',
    _ => null,
  };

  String valueOf(Organization org) =>
      switch (this) {
        SchoolField.name => org.name,
        SchoolField.address => org.address,
        SchoolField.phone => org.phone,
        SchoolField.email => org.email,
        SchoolField.numberPrefix => org.numberPrefix,
      } ??
      '';

  /// Cleans the typed value; null means "clear it".
  String? clean(String value) {
    final trimmed = value.trim();
    final cleaned = switch (this) {
      SchoolField.phone => trimmed.replaceAll(RegExp(r'[\s-]'), ''),
      SchoolField.email => trimmed.toLowerCase(),
      SchoolField.numberPrefix => trimmed.toUpperCase(),
      _ => trimmed,
    };
    return cleaned.isEmpty ? null : cleaned;
  }

  String? validate(String? value) {
    if (value == null) return isRequired ? '$label is required' : null;
    return switch (this) {
      SchoolField.phone => ValidationUtil.validatePhoneNumber(value),
      SchoolField.email => ValidationUtil.validateEmail(value),
      SchoolField.numberPrefix =>
        RegExp(r'^[A-Z0-9]{2,8}$').hasMatch(value)
            ? null
            : 'Use 2 to 8 letters or numbers, no spaces',
      _ => null,
    };
  }
}

/// 10 · Check your school. The first owner or admin in checks the details
/// Hamrash filled in, fixes any, then taps "Looks good".
class ConfirmSchoolViewModel extends BaseViewModel {
  ConfirmSchoolViewModel({
    required Organization organization,
    required this.clerkUserId,
    required this.firstName,
    required this.onConfirmed,
    SchoolService? service,
    ImageService? imageService,
    ImagePicker? imagePicker,
  }) : _organization = organization,
       _service = service ?? locator<SchoolService>(),
       _imageService = imageService,
       _imagePicker = imagePicker ?? ImagePicker();

  final String clerkUserId;
  final String? firstName;
  final ValueChanged<Organization> onConfirmed;
  final SchoolService _service;
  final ImageService? _imageService;
  final ImagePicker _imagePicker;

  Organization _organization;
  bool _uploadingLogo = false;

  Organization get organization => _organization;
  bool get uploadingLogo => _uploadingLogo;

  String get greeting => switch (firstName?.trim()) {
    final String name when name.isNotEmpty => 'Welcome, $name',
    _ => 'Welcome',
  };

  /// Saves one field. Returns the message to show under the field, or null
  /// once it's saved.
  Future<String?> saveField(SchoolField field, String input) async {
    final value = field.clean(input);
    final problem = field.validate(value);
    if (problem != null) return problem;
    if (value == field.clean(field.valueOf(_organization))) return null;

    try {
      _organization = await _service.updateDetails(_organization.id, {
        field.column: value,
      });
      notifyListeners();
      return null;
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'ConfirmSchool.saveField.${field.name}',
        showErrorModal: false,
      );
      return "Couldn't save that. Check your connection and try again.";
    }
  }

  Future<void> changeLogo() async {
    if (_uploadingLogo) return;
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 90,
    );
    if (picked == null) return;

    _uploadingLogo = true;
    notifyListeners();
    try {
      final image = await (_imageService ?? locator<ImageService>())
          .uploadImage(
            await picked.readAsBytes(),
            'school-logo-${_organization.id}',
            metadata: {'organization_id': _organization.id},
          );
      final url = image.variants?.firstOrNull;
      if (image.id == null || url == null) {
        throw StateError('Logo upload returned no image');
      }
      _organization = await _service.updateDetails(_organization.id, {
        'logo_id': image.id,
        'logo_url': url,
      });
      AppToast.show('Logo added', type: AppToastType.success);
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'ConfirmSchool.changeLogo',
        showErrorModal: false,
      );
      AppToast.show(
        "Couldn't add the logo. Try again.",
        type: AppToastType.error,
      );
    } finally {
      _uploadingLogo = false;
      notifyListeners();
    }
  }

  Future<void> confirm() async {
    if (busy) return;
    setBusy(true);
    try {
      final confirmed = await _service.confirmDetails(
        _organization.id,
        clerkUserId: clerkUserId,
      );
      setBusy(false);
      onConfirmed(confirmed);
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'ConfirmSchool.confirm',
        userMessage:
            "We couldn't save that. Check your connection and try again.",
      );
    }
  }
}
