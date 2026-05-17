import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/teacher_model.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/image_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/state_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/teacher_service.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

enum CreateTeacherStep { identity, personal, photo }

class CreateTeacherViewModel extends BaseViewModel {
  CreateTeacherViewModel({this.existing});

  final TeacherModel? existing;
  bool get isEdit => existing != null;

  final _teacherService = locator<TeacherService>();
  final _imageService = locator<ImageService>();
  final _stateService = locator<StateService>();

  final formKeyIdentity = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  final genderDisplayController = TextEditingController();
  final stateDisplayController = TextEditingController();
  final addressController = TextEditingController();

  String? _selectedGender;
  String? get selectedGender => _selectedGender;

  String? _selectedState;
  String? get selectedState => _selectedState;

  final List<String> availableGenders = ['Male', 'Female'];
  List<String> availableStates = [];

  XFile? selectedImage;
  String? _existingAvatarUrl;
  String? get existingAvatarUrl => _existingAvatarUrl;

  final pageController = PageController();
  CreateTeacherStep _currentStep = CreateTeacherStep.identity;
  CreateTeacherStep get currentStep => _currentStep;

  bool suppressValidationMessages = false;

  final ImagePicker _imagePicker = ImagePicker();

  void init() {
    if (existing != null) {
      firstNameController.text = existing!.firstName;
      lastNameController.text = existing!.lastName;
      emailController.text = existing!.email ?? '';
      phoneController.text = existing!.phone ?? '';
      _selectedGender = existing!.gender;
      if (existing!.gender != null) {
        final g = existing!.gender!;
        genderDisplayController.text =
            g[0].toUpperCase() + g.substring(1);
      }
      _selectedState = existing!.state;
      stateDisplayController.text = existing!.state ?? '';
      addressController.text = existing!.address ?? '';
      _existingAvatarUrl = existing!.avatarUrl;
    }
    fetchStates();
  }

  void dismissValidationMessages() {
    suppressValidationMessages = true;
    notifyListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentStep == CreateTeacherStep.identity) {
        formKeyIdentity.currentState?.validate();
      }
    });
  }

  void selectGender(String displayValue) {
    _selectedGender = displayValue.toLowerCase();
    genderDisplayController.text = displayValue;
    notifyListeners();
    NavigationService.popScreen();
  }

  void selectState(String value) {
    _selectedState = value;
    stateDisplayController.text = value;
    notifyListeners();
    NavigationService.popScreen();
  }

  Future<void> fetchStates() async {
    if (availableStates.isNotEmpty) return;
    try {
      final states = await _stateService.fetchStates();
      availableStates = states.map((s) => s.name).toList();
    } catch (_) {
      availableStates = ['Lagos', 'Abuja', 'Kano', 'Rivers'];
    }
    notifyListeners();
  }

  bool goNext() {
    suppressValidationMessages = false;
    if (_currentStep == CreateTeacherStep.identity) {
      if (!(formKeyIdentity.currentState?.validate() ?? false)) return false;
    }
    final nextIndex = _currentStep.index + 1;
    pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
    _currentStep = CreateTeacherStep.values[nextIndex];
    notifyListeners();
    return true;
  }

  void goBack() {
    if (_currentStep == CreateTeacherStep.identity) return;
    final prevIndex = _currentStep.index - 1;
    pageController.animateToPage(
      prevIndex,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
    _currentStep = CreateTeacherStep.values[prevIndex];
    notifyListeners();
  }

  bool get isLastStep => _currentStep == CreateTeacherStep.photo;

  Future<void> pickImageFromGallery() async {
    if (selectedImage != null) {
      await _deletePersistedPickIfAny();
      selectedImage = null;
      notifyListeners();
      return;
    }
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) {
        selectedImage = await _persistPickedImage(picked);
        notifyListeners();
      }
    } catch (e, st) {
      await handleError(
        e,
        stackTrace: st,
        context: 'CreateTeacherViewModel.pickImageFromGallery',
        userMessage: 'Failed to pick image. Please try again.',
      );
    }
  }

  Future<TeacherModel?> submit() async {
    setBusy(true);
    String? uploadedImageId;
    String? uploadedImageUrl;

    try {
      if (selectedImage != null) {
        final bytes = await selectedImage!.readAsBytes();
        final filename = 'teacher_${const Uuid().v4()}';
        final response = await _imageService.uploadImage(
          bytes,
          filename,
          metadata: {'Type': 'teacher_profile'},
        );
        uploadedImageId = response.id;
        uploadedImageUrl = response.variants?.firstOrNull;
      }

      final model = TeacherModel(
        id: existing?.id,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim().isEmpty
            ? null
            : emailController.text.trim(),
        phone: phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
        gender: _selectedGender,
        state: _selectedState,
        address: addressController.text.trim().isEmpty
            ? null
            : addressController.text.trim(),
        avatarUrl: uploadedImageUrl ?? _existingAvatarUrl,
        avatarUrlId: uploadedImageId ?? existing?.avatarUrlId,
        fcmToken: existing?.fcmToken,
        isActive: existing?.isActive ?? true,
        homeroomClassId: existing?.homeroomClassId,
        homeroomRole: existing?.homeroomRole,
      );

      final TeacherModel result;
      if (isEdit) {
        result = await _teacherService.updateTeacher(existing!.id!, model);
      } else {
        result = await _teacherService.insertTeacher(model);
      }

      await _deletePersistedPickIfAny();
      return result;
    } catch (e, st) {
      if (uploadedImageId != null) {
        await _imageService.deleteImage(uploadedImageId).catchError((_) {});
      }
      await handleError(
        e,
        stackTrace: st,
        context: 'CreateTeacherViewModel.submit',
        userMessage: isEdit
            ? 'Failed to update teacher. Please try again.'
            : 'Failed to create teacher. Please try again.',
      );
      return null;
    } finally {
      setBusy(false);
    }
  }

  Future<void> _deletePersistedPickIfAny() async {
    final path = selectedImage?.path;
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<XFile> _persistPickedImage(XFile picked) async {
    final bytes = await picked.readAsBytes();
    final dir = await getApplicationSupportDirectory();
    final ext = p.extension(picked.path);
    final suffix = ext.isNotEmpty && ext.length <= 6 ? ext : '.jpg';
    final destPath = p.join(
        dir.path, 'teacher_pick_${const Uuid().v4()}$suffix');
    await File(destPath).writeAsBytes(bytes, flush: true);
    return XFile(destPath);
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    genderDisplayController.dispose();
    stateDisplayController.dispose();
    addressController.dispose();
    pageController.dispose();
    super.dispose();
  }
}
