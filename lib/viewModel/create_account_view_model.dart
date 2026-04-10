import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/services/supabase_services/role_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/state_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';
import 'package:hamrash_admin/widgets/step_indicator.dart';

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

  final PageController pageController = PageController();

  final StateService stateService = locator<StateService>();
  final RoleService roleService = locator<RoleService>();


  List<String> availableStates = [];

  List<String> availableRoles = [];

  List<String> availableGenders = [
    'Male',
    'Female',
    'Prefer not to say',
  ];

  String? _selectedGender;
  String? get selectedGender => _selectedGender;

  String? _selectedState;
  String? get selectedState => _selectedState;

  String? _selectedRole;
  String? get selectedRole => _selectedRole;

  CreateAccountStep _currentStep = CreateAccountStep.name;
  CreateAccountStep get currentStep => _currentStep;

  int get currentPageIndex => _currentStep.index;

  void init(BuildContext context) {
    this.context = context;
    emailController.text = clerkEmail ?? '';
  }

  void selectGender(String? value) {
    _selectedGender = value;
    genderDisplayController.text = value ?? '';
    notifyListeners();
  }

  void selectState(String? value) {
    _selectedState = value;
    stateDisplayController.text = value ?? '';
    notifyListeners();
  }

  void selectRole(String? value) {
    _selectedRole = value;
    roleDisplayController.text = value ?? '';
    notifyListeners();
  }

  Future<void> goNext(BuildContext context) async {
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
    pageController.jumpToPage(
      nextIndex,
 
    );
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
    pageController.jumpToPage(
      prevIndex,
   
    );
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
    setBusy(true);
    try {
      final roles = await roleService.fetchRoles();
      if (roles.isNotEmpty) {
        availableRoles = roles.map((role) => role.name).toList();
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
      notifyListeners();
    }
  }
}
