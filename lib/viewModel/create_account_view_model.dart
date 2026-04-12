import 'dart:typed_data';

import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/admin_profile_model.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/image_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/admin_profile_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/role_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/state_service.dart';
import 'package:hamrash_admin/api/models/supabase_models/role_model.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';
import 'package:hamrash_admin/views/home/home.dart';
import 'package:hamrash_admin/widgets/step_indicator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class CreateAccountViewModel extends BaseViewModel {
  String title = 'Create account';
  late BuildContext context;

  final formKeyName = GlobalKey<FormState>();
  final formKeyDetails = GlobalKey<FormState>();

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final genderDisplayController = TextEditingController();

  final stateDisplayController = TextEditingController();
  final roleDisplayController = TextEditingController();
  final locationController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  XFile? selectedImage;
  final PageController pageController = PageController();

  final StateService stateService = locator<StateService>();
  final RoleService roleService = locator<RoleService>();
  final ImageService imageService = locator<ImageService>();
  final AdminProfileService adminProfileService =
      locator<AdminProfileService>();

  List<String> availableStates = [];

  List<RoleModel> availableRoles = [];

  bool _rolesFetchAttempted = false;

  List<String> availableGenders = ['Male', 'Female'];

  String? _selectedGender;
  String? get selectedGender => _selectedGender;

  String? _selectedState;
  String? get selectedState => _selectedState;

  String? _selectedRole;
  String? get selectedRole => _selectedRole;

  CreateAccountStep _currentStep = CreateAccountStep.name;
  CreateAccountStep get currentStep => _currentStep;

  bool suppressValidationMessages = false;

  int get currentPageIndex => _currentStep.index;

  /// Clears red error state until the user taps Continue again (validators still run on Continue).
  void dismissValidationMessages() {
    suppressValidationMessages = true;
    notifyListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (_currentStep) {
        case CreateAccountStep.name:
          formKeyName.currentState?.validate();
          break;
        case CreateAccountStep.details:
          formKeyDetails.currentState?.validate();
          break;
        case CreateAccountStep.profileImage:
          break;
      }
    });
  }

  void init(BuildContext context) async {
    this.context = context;
    emailController.text = clerkEmail ?? '';
    await Future.wait([fetchStates(), fetchRoles()]);
  }

  void selectGender(String? value) {
    _selectedGender = value;
    genderDisplayController.text = value ?? '';
    notifyListeners();
    NavigationService.popScreen();
  }

  void selectState(String? value) {
    _selectedState = value;
    stateDisplayController.text = value ?? '';
    notifyListeners();
    NavigationService.popScreen();
  }

  void selectRole(RoleModel? role) {
    _selectedRole = role?.name;
    roleDisplayController.text = role?.displayLabel ?? '';
    notifyListeners();
    NavigationService.popScreen();
  }

  Future<void> goNext(BuildContext context) async {
    suppressValidationMessages = false;
    switch (_currentStep) {
      case CreateAccountStep.name:
        if (!(formKeyName.currentState?.validate() ?? false)) return;
        break;
      case CreateAccountStep.details:
        if (!(formKeyDetails.currentState?.validate() ?? false)) return;
        break;
      case CreateAccountStep.profileImage:
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        return;
    }

    final nextIndex = _currentStep.index + 1;
    pageController.jumpToPage(nextIndex);
    _currentStep = CreateAccountStep.values[nextIndex];
    notifyListeners();
  }

  void goBack(BuildContext context) {
    if (_currentStep == CreateAccountStep.name) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    final prevIndex = _currentStep.index - 1;
    pageController.jumpToPage(prevIndex);
    _currentStep = CreateAccountStep.values[prevIndex];
    notifyListeners();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    genderDisplayController.dispose();
    stateDisplayController.dispose();
    roleDisplayController.dispose();
    locationController.dispose();
    pageController.dispose();
    super.dispose();
  }

  String? get clerkEmail {
    try {
      final clerkAuth = ClerkAuth.of(context);
      final user = clerkAuth.user;

      try {
        final email = user?.emailAddresses?.firstOrNull?.emailAddress;
        if (email != null) return email;
      } catch (_) {
        try {
          final email = user?.emailAddresses?.first.emailAddress;
          if (email != null) return email;
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  Future<void> fetchStates() async {
    if (availableStates.isNotEmpty) return;
    setBusy(true);
    try {
      final states = await stateService.fetchStates();
      if (states.isNotEmpty) {
        availableStates = states.map((state) => state.name).toList();
      }
    } catch (e, stackTrace) {
      await handleError(
        e,
        stackTrace: stackTrace,
        context: 'CreateAccountViewModel.fetchStates',
        userMessage: 'Failed to load states. Using default list.',
      );
    } finally {
      setBusy(false);
      if (availableStates.isEmpty) {
        availableStates = ['Lagos', 'Abuja', 'Kano', 'Rivers'];
      }
      notifyListeners();
    }
  }

  Future<void> fetchRoles() async {
    if (_rolesFetchAttempted) return;
    setBusy(true);
    try {
      final roles = await roleService.fetchRoles();
      if (roles.isNotEmpty) {
        availableRoles = roles;
      }
    } catch (e, stackTrace) {
      await handleError(
        e,
        stackTrace: stackTrace,
        context: 'CreateAccountViewModel.fetchRoles',
        userMessage: 'Failed to load roles. Using default list.',
      );
    } finally {
      setBusy(false);
      if (availableRoles.isEmpty) {
        availableRoles = [];
      }
      _rolesFetchAttempted = true;
      notifyListeners();
    }
  }

  Future<void> pickImageFromGallery() async {
    if (selectedImage != null) {
      selectedImage = null;
      notifyListeners();
      return;
    }
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (image != null) {
        selectedImage = image;
        notifyListeners();
      }
    } catch (e, stackTrace) {
      await handleError(
        e,
        stackTrace: stackTrace,
        context: 'CreateAccountViewModel.pickImageFromGallery',
        userMessage: 'Failed to pick image. Please try again.',
      );
    }
  }

  String? get clerkId {
    try {
      final clerkAuth = ClerkAuth.of(context);
      return clerkAuth.user?.id;
    } catch (_) {
      return null;
    }
  }

  Future<void> submitAccount() async {
    if (!(formKeyName.currentState?.validate() ?? false) ||
        !(formKeyDetails.currentState?.validate() ?? false))
      return;

    setBusy(true);
    String? uploadedImageId;
    String? uploadedImageUrl;

    try {
      if (selectedImage != null) {
        final Uint8List imageBytes = await selectedImage!.readAsBytes();

        final filename = 'profile_${const Uuid().v4()}';

        final imageResponse = await imageService.uploadImage(
          imageBytes,
          filename,
          metadata: {'Type': 'artisan_profile'},
        );

        uploadedImageId = imageResponse.id;
        if (imageResponse.variants != null &&
            imageResponse.variants!.isNotEmpty) {
          uploadedImageUrl = imageResponse.variants!.first;
        }

        if (uploadedImageId == null || uploadedImageUrl == null) {
          throw Exception(
            'Failed to get image ID or URL from Cloudflare response',
          );
        }
      }

      final adminProfile = AdminProfileModel(
        id: const Uuid().v4(),
        isActive: true,
        clerkId: clerkId,
        fullName: fullNameController.text,
        email: emailController.text,
        phoneNumber: phoneController.text,
        gender: selectedGender,
        state: selectedState,
        role: selectedRole,
        avatarUrl: uploadedImageUrl,
        avatarUrlId: uploadedImageId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        await adminProfileService.insertAdminProfile(adminProfile.toJson());
      } catch (e, stackTrace) {
        if (uploadedImageId != null) {
          try {
            await imageService.deleteImage(uploadedImageId);
          } catch (deleteError) {
            await handleError(
              deleteError,
              stackTrace: stackTrace,
              context:
                  'CreateAccountViewModel.submitAccount - Cloudflare delete cleanup',
              userMessage: null,
            );
          }
        }
        rethrow;
      }

      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed(Home.routeName);
      }
    } catch (e, stackTrace) {
      await handleError(
        e,
        stackTrace: stackTrace,
        context: 'CreateAccountViewModel.submitAccount',
        userMessage: 'Failed to create account. Please try again.',
      );
    } finally {
      setBusy(false);
    }
  }
}
