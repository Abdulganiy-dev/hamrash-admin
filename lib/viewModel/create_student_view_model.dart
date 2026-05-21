import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/class_model.dart';
import 'package:hamrash_admin/api/models/supabase_models/student_model.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/image_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/state_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/student_service.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

enum CreateStudentStep { identity, personal, academic, photo }

class CreateStudentViewModel extends BaseViewModel {
  CreateStudentViewModel({this.existing});

  final StudentModel? existing;
  bool get isEdit => existing != null;

  final _studentService = locator<StudentService>();
  final _imageService = locator<ImageService>();
  final _stateService = locator<StateService>();
  final _classService = locator<ClassService>();

  // Step 1
  final formKeyIdentity = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  // Step 2
  final genderDisplayController = TextEditingController();
  final stateDisplayController = TextEditingController();
  final addressController = TextEditingController();
  final dobDisplayController = TextEditingController();

  // Step 3
  final admissionNumberController = TextEditingController();
  final admissionDateDisplayController = TextEditingController();
  final classDisplayController = TextEditingController();

  String? _selectedGender;
  String? get selectedGender => _selectedGender;

  String? _selectedState;
  String? get selectedState => _selectedState;

  DateTime? _dateOfBirth;
  DateTime? get dateOfBirth => _dateOfBirth;

  DateTime? _admissionDate;
  DateTime? get admissionDate => _admissionDate;

  String? _selectedClassId;
  String? get selectedClassId => _selectedClassId;
  ClassModel? get selectedClass {
    if (_selectedClassId == null) return null;
    for (final c in availableClasses) {
      if (c.id == _selectedClassId) return c;
    }
    return null;
  }

  final List<String> availableGenders = ['Male', 'Female'];
  List<String> availableStates = [];
  List<ClassModel> availableClasses = [];

  XFile? selectedImage;
  String? _existingAvatarUrl;
  String? get existingAvatarUrl => _existingAvatarUrl;

  final pageController = PageController();
  CreateStudentStep _currentStep = CreateStudentStep.identity;
  CreateStudentStep get currentStep => _currentStep;

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
        genderDisplayController.text = g[0].toUpperCase() + g.substring(1);
      }
      _selectedState = existing!.state;
      stateDisplayController.text = existing!.state ?? '';
      addressController.text = existing!.address ?? '';
      _dateOfBirth = existing!.dateOfBirth;
      if (existing!.dateOfBirth != null) {
        dobDisplayController.text = _formatDate(existing!.dateOfBirth!);
      }
      admissionNumberController.text = existing!.admissionNumber ?? '';
      _admissionDate = existing!.admissionDate;
      if (existing!.admissionDate != null) {
        admissionDateDisplayController.text =
            _formatDate(existing!.admissionDate!);
      }
      _selectedClassId = existing!.classId;
      _existingAvatarUrl = existing!.avatarUrl;
    }
    fetchStates();
    fetchClasses();
  }

  void dismissValidationMessages() {
    suppressValidationMessages = true;
    notifyListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentStep == CreateStudentStep.identity) {
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

  void selectClass(ClassModel cls) {
    _selectedClassId = cls.id;
    classDisplayController.text = cls.displayName;
    notifyListeners();
    NavigationService.popScreen();
  }

  void setDateOfBirth(DateTime d) {
    _dateOfBirth = d;
    dobDisplayController.text = _formatDate(d);
    notifyListeners();
  }

  void setAdmissionDate(DateTime d) {
    _admissionDate = d;
    admissionDateDisplayController.text = _formatDate(d);
    notifyListeners();
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

  Future<void> fetchClasses() async {
    if (availableClasses.isNotEmpty) return;
    try {
      availableClasses = await _classService.fetchClasses();
      if (_selectedClassId != null) {
        final c = selectedClass;
        if (c != null) classDisplayController.text = c.displayName;
      }
      notifyListeners();
    } catch (_) {}
  }

  bool goNext() {
    suppressValidationMessages = false;
    if (_currentStep == CreateStudentStep.identity) {
      if (!(formKeyIdentity.currentState?.validate() ?? false)) return false;
    }
    final nextIndex = _currentStep.index + 1;
    pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
    _currentStep = CreateStudentStep.values[nextIndex];
    notifyListeners();
    return true;
  }

  void goBack() {
    if (_currentStep == CreateStudentStep.identity) return;
    final prevIndex = _currentStep.index - 1;
    pageController.animateToPage(
      prevIndex,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
    _currentStep = CreateStudentStep.values[prevIndex];
    notifyListeners();
  }

  bool get isLastStep => _currentStep == CreateStudentStep.photo;

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
        context: 'CreateStudentViewModel.pickImageFromGallery',
        userMessage: 'Failed to pick image. Please try again.',
      );
    }
  }

  Future<StudentModel?> submit() async {
    setBusy(true);
    String? uploadedImageId;
    String? uploadedImageUrl;

    try {
      if (selectedImage != null) {
        final bytes = await selectedImage!.readAsBytes();
        final filename = 'student_${const Uuid().v4()}';
        final response = await _imageService.uploadImage(
          bytes,
          filename,
          metadata: {'Type': 'student_profile'},
        );
        uploadedImageId = response.id;
        uploadedImageUrl = response.variants?.firstOrNull;
      }

      final model = StudentModel(
        id: existing?.id,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: _nullIfEmpty(emailController.text),
        phone: _nullIfEmpty(phoneController.text),
        gender: _selectedGender,
        dateOfBirth: _dateOfBirth,
        admissionNumber: _nullIfEmpty(admissionNumberController.text),
        admissionDate: _admissionDate,
        state: _selectedState,
        address: _nullIfEmpty(addressController.text),
        avatarUrl: uploadedImageUrl ?? _existingAvatarUrl,
        avatarUrlId: uploadedImageId ?? existing?.avatarUrlId,
        fcmToken: existing?.fcmToken,
        isActive: existing?.isActive ?? true,
        classId: _selectedClassId,
      );

      final StudentModel result;
      if (isEdit) {
        result = await _studentService.updateStudent(existing!.id!, model);
      } else {
        result = await _studentService.insertStudent(model);
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
        context: 'CreateStudentViewModel.submit',
        userMessage: isEdit
            ? 'Failed to update student. Please try again.'
            : 'Failed to create student. Please try again.',
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
        dir.path, 'student_pick_${const Uuid().v4()}$suffix');
    await File(destPath).writeAsBytes(bytes, flush: true);
    return XFile(destPath);
  }

  String _formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    genderDisplayController.dispose();
    stateDisplayController.dispose();
    addressController.dispose();
    dobDisplayController.dispose();
    admissionNumberController.dispose();
    admissionDateDisplayController.dispose();
    classDisplayController.dispose();
    pageController.dispose();
    super.dispose();
  }
}
