import 'package:flutter/material.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';
import 'package:hamrash_admin/views/onboarding/widgets/auth_onboarding_widgets.dart';

enum JoinPhase {
  enterCode,
  wrongCode,
  tooManyTries,
  confirmStaff,
  codeForAnotherApp,
  confirmOwner,
  addRole,
  roleAlreadyCovered,
}

class JoinViewModel extends BaseViewModel {
  JoinViewModel({
    this.phase = JoinPhase.enterCode,
    this.email = '',
    String? initialName,
    this.schoolName = '',
    this.location = '',
    this.role = '',
    this.schoolCode = '',
    this.targetApp = '',
    this.currentRole = 'Owner',
    this.newRole = 'Principal',
    this.coveredRole = 'Admin',
    String? initialCode,
    this.onContinue,
    this.onUseAnotherAccount,
    this.onJoin,
    this.onDifferentCode,
    this.onSignOut,
  }) : code = TextEditingController(
         text:
             initialCode ??
             '',
       ),
       fullName = TextEditingController(text: initialName ?? ''),
       phoneNumber = TextEditingController() {
    code.addListener(notifyListeners);
  }

  JoinPhase phase;
  final String email;
  final String schoolName;
  final String location;
  final String role;
  final String schoolCode;
  final String targetApp;
  final String currentRole;
  final String newRole;
  final String coveredRole;
  final TextEditingController code;
  final TextEditingController fullName;
  final TextEditingController phoneNumber;
  final Future<JoinPhase?> Function(String code)? onContinue;
  final VoidCallback? onUseAnotherAccount;
  final VoidCallback? onJoin;
  final VoidCallback? onDifferentCode;
  final VoidCallback? onSignOut;

  bool get showBackButton => switch (phase) {
    JoinPhase.confirmStaff ||
    JoinPhase.confirmOwner ||
    JoinPhase.codeForAnotherApp => true,
    _ => false,
  };

  String? get codeError => phase == JoinPhase.wrongCode
      ? "We couldn't find that code. Check it with whoever sent it to you."
      : null;

  bool get isCodeLocked => phase == JoinPhase.tooManyTries;

  bool get canContinue =>
      !isCodeLocked && JoinCodeInputFormatter.format(code.text).length == 9;

  String? get codeAttemptsMessage => switch (phase) {
    JoinPhase.wrongCode => '3 more tries this hour.',
    JoinPhase.tooManyTries =>
      "Too many tries\nFor your school's safety, codes are paused. Try again in 42 minutes.",
    _ => null,
  };

  Future<void> continueWithCode() async {
    if (!canContinue) return;
    final nextPhase = await onContinue?.call(code.text);
    if (nextPhase != null) setPhase(nextPhase);
  }

  void setPhase(JoinPhase nextPhase) {
    if (phase == nextPhase) return;
    phase = nextPhase;
    notifyListeners();
  }

  void useDifferentCode() {
    onDifferentCode?.call();
    setPhase(JoinPhase.enterCode);
  }

  void handleBack(BuildContext context, VoidCallback? onBack) {
    if (phase != JoinPhase.enterCode) {
      setPhase(JoinPhase.enterCode);
      return;
    }
    if (onBack != null) {
      onBack();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void joinSchool() => onJoin?.call();

  void skipAdditionalRole() => onJoin?.call();

  void useAnotherAccount() => onUseAnotherAccount?.call();

  void signOut() => onSignOut?.call();

  @override
  void dispose() {
    code.removeListener(notifyListeners);
    code.dispose();
    fullName.dispose();
    phoneNumber.dispose();
    super.dispose();
  }
}
