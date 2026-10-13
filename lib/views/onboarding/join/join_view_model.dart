import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/claim_code_check.dart';
import 'package:hamrash_admin/api/models/organization_models/organization_member.dart';
import 'package:hamrash_admin/api/services/supabase_services/organization_member_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';
import 'package:hamrash_admin/views/onboarding/widgets/auth_onboarding_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum JoinPhase {
  enterCode,
  wrongCode,
  tooManyTries,
  schoolInactive,
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
    this.memberships = const [],
    OrganizationMemberService? service,
    this.onUseAnotherAccount,
    this.onJoin,
    this.onDifferentCode,
    this.onSignOut,
  }) : _service = service ?? locator<OrganizationMemberService>(),
       code = TextEditingController(text: initialCode ?? ''),
       fullName = TextEditingController(text: initialName ?? ''),
       phoneNumber = TextEditingController() {
    code.addListener(_onCodeChanged);
    fullName.addListener(_onFullNameChanged);
  }

  JoinPhase phase;
  final String email;
  String schoolName;
  String location;
  String role;
  String schoolCode;
  String targetApp;
  String currentRole;
  String newRole;
  String coveredRole;
  final List<OrganizationMember> memberships;
  final TextEditingController code;
  final TextEditingController fullName;
  final TextEditingController phoneNumber;
  final OrganizationMemberService _service;
  final VoidCallback? onUseAnotherAccount;
  final VoidCallback? onJoin;
  final VoidCallback? onDifferentCode;
  final VoidCallback? onSignOut;

  ClaimCodeCheck? _checkedCode;
  String? _checkedInput;
  Timer? _lockTimer;
  int? triesLeft;
  DateTime? retryAt;
  String? nameError;

  bool get showBackButton => switch (phase) {
    JoinPhase.confirmStaff ||
    JoinPhase.confirmOwner ||
    JoinPhase.codeForAnotherApp => true,
    _ => false,
  };

  String? get codeError =>
      phase == JoinPhase.wrongCode
          ? "We couldn't find that code. Check it with whoever sent it to you."
          : null;

  bool get isCodeLocked => phase == JoinPhase.tooManyTries;

  bool get canContinue =>
      !busy &&
      !isCodeLocked &&
      JoinCodeInputFormatter.format(code.text).length == 9;

  String? get codeAttemptsMessage {
    if (!isCodeLocked) return null;
    final remaining = retryAt?.difference(DateTime.now());
    final minutes =
        remaining == null
            ? null
            : (remaining.inSeconds / 60).ceil().clamp(1, 60);
    return 'Too many tries\nFor your school\'s safety, codes are paused. '
        'Try again in ${minutes == null ? 'an hour' : '$minutes minutes'}.';
  }

  void _onCodeChanged() {
    if (phase == JoinPhase.wrongCode || phase == JoinPhase.schoolInactive) {
      phase = JoinPhase.enterCode;
      triesLeft = null;
      _checkedCode = null;
      _checkedInput = null;
    }
    notifyListeners();
  }

  void _onFullNameChanged() {
    if (nameError != null) {
      nameError = null;
      notifyListeners();
    }
  }

  Future<void> continueWithCode() async {
    if (!canContinue) return;
    final submittedCode = code.text;
    setBusy(true);
    try {
      final result = await _service.checkClaimCode(submittedCode);
      if (!isDisposed && code.text == submittedCode) {
        _checkedInput = submittedCode;
        _applyCheck(result);
      }
    } catch (error, stackTrace) {
      await handleDatabaseError(
        error,
        stackTrace: stackTrace,
        operation: 'check_claim_code',
        userMessage: 'Could not check that code. Try again.',
      );
    } finally {
      setBusy(false);
    }
  }

  void _applyCheck(ClaimCodeCheck result) {
    _checkedCode = result;
    triesLeft = result.triesLeft;
    retryAt = result.retryAt;
    if (result.schoolName != null) schoolName = result.schoolName!;
    if (result.schoolCode != null) schoolCode = result.schoolCode!;
    location =
        result.schoolAddress?.trim().isNotEmpty == true
            ? result.schoolAddress!
            : result.schoolState ?? '';
    if (result.role != null) role = result.role!.displayName;

    switch (result.status) {
      case ClaimCodeStatus.notFound:
        setPhase(JoinPhase.wrongCode);
      case ClaimCodeStatus.locked:
        _scheduleUnlock();
        setPhase(JoinPhase.tooManyTries);
      case ClaimCodeStatus.schoolInactive:
        setPhase(JoinPhase.schoolInactive);
      case ClaimCodeStatus.alreadyMember:
        if (result.app != 'admin') {
          targetApp = result.role?.displayName ?? result.app ?? '';
          setPhase(JoinPhase.codeForAnotherApp);
          return;
        }
        currentRole = role;
        coveredRole = role;
        setPhase(JoinPhase.roleAlreadyCovered);
      case ClaimCodeStatus.ok:
        if (result.app != 'admin') {
          targetApp = result.role?.displayName ?? result.app ?? '';
          setPhase(JoinPhase.codeForAnotherApp);
          return;
        }
        if (result.needsName == true) {
          setPhase(JoinPhase.confirmOwner);
          return;
        }
        final existing = memberships.where(
          (member) =>
              member.organizationId == result.organizationId &&
              member.status == OrganizationMemberStatus.active,
        );
        if (existing.isNotEmpty) {
          currentRole = existing.first.role.displayName;
          newRole = role;
          coveredRole = role;
          if (existing.any(
            (member) =>
                member.role == result.role ||
                member.role == OrganizationMemberRole.owner,
          )) {
            setPhase(JoinPhase.roleAlreadyCovered);
          } else {
            setPhase(JoinPhase.addRole);
          }
          return;
        }
        setPhase(JoinPhase.confirmStaff);
    }
  }

  void _scheduleUnlock() {
    _lockTimer?.cancel();
    final wait = retryAt?.difference(DateTime.now());
    if (wait == null) return;
    _lockTimer = Timer(wait.isNegative ? Duration.zero : wait, () {
      if (!isDisposed && isCodeLocked) {
        retryAt = null;
        setPhase(JoinPhase.enterCode);
      }
    });
  }

  void setPhase(JoinPhase nextPhase) {
    if (phase == nextPhase) return;
    phase = nextPhase;
    notifyListeners();
  }

  void useDifferentCode() {
    if (busy) return;
    _checkedCode = null;
    _checkedInput = null;
    triesLeft = null;
    retryAt = null;
    code.clear();
    onDifferentCode?.call();
    setPhase(JoinPhase.enterCode);
  }

  void handleBack(BuildContext context, VoidCallback? onBack) {
    if (busy) return;
    if (phase != JoinPhase.enterCode) {
      useDifferentCode();
      return;
    }
    if (onBack != null) {
      onBack();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> joinSchool() async {
    if (busy) return;
    if (phase == JoinPhase.roleAlreadyCovered) {
      onJoin?.call();
      return;
    }
    if (_checkedCode?.status != ClaimCodeStatus.ok ||
        _checkedInput != code.text) {
      return;
    }
    if (phase != JoinPhase.confirmStaff &&
        phase != JoinPhase.confirmOwner &&
        phase != JoinPhase.addRole) {
      return;
    }

    String? firstName;
    String? lastName;
    if (_checkedCode!.needsName == true) {
      final names = fullName.text.trim().split(RegExp(r'\s+'));
      if (names.length < 2) {
        nameError = 'Enter your first and last name.';
        notifyListeners();
        return;
      }
      firstName = names.first;
      lastName = names.skip(1).join(' ');
    }

    setBusy(true);
    var redeemed = false;
    try {
      final phone = phoneNumber.text.trim();
      final member = await _service.redeemClaimCode(
        code: code.text,
        firstName: firstName,
        lastName: lastName,
        email: email.isEmpty ? null : email,
        phone:
            phone.isEmpty
                ? null
                : '+234${phone.replaceFirst(RegExp(r'^0'), '')}',
      );
      if (isDisposed) return;
      if (member == null) {
        triesLeft = null;
        setPhase(JoinPhase.wrongCode);
      } else {
        redeemed = true;
      }
    } on PostgrestException catch (error, stackTrace) {
      if (error.message.startsWith('Too many wrong codes')) {
        try {
          final result = await _service.checkClaimCode(code.text);
          if (!isDisposed) _applyCheck(result);
        } catch (checkError, checkStackTrace) {
          await handleDatabaseError(
            checkError,
            stackTrace: checkStackTrace,
            operation: 'check_claim_code',
          );
        }
      } else if (error.message == 'This school is not currently active') {
        setPhase(JoinPhase.schoolInactive);
      } else if (error.message == 'You already have this role at this school') {
        currentRole = role;
        coveredRole = role;
        setPhase(JoinPhase.roleAlreadyCovered);
      } else {
        await handleDatabaseError(
          error,
          stackTrace: stackTrace,
          operation: 'redeem_claim_code',
          userMessage: 'Could not join this school. Try again.',
        );
      }
    } catch (error, stackTrace) {
      await handleDatabaseError(
        error,
        stackTrace: stackTrace,
        operation: 'redeem_claim_code',
        userMessage: 'Could not join this school. Try again.',
      );
    } finally {
      setBusy(false);
    }
    if (redeemed && !isDisposed) onJoin?.call();
  }

  void skipAdditionalRole() {
    if (!busy) onJoin?.call();
  }

  void useAnotherAccount() => onUseAnotherAccount?.call();

  void signOut() => onSignOut?.call();

  @override
  void dispose() {
    _lockTimer?.cancel();
    code.removeListener(_onCodeChanged);
    fullName.removeListener(_onFullNameChanged);
    code.dispose();
    fullName.dispose();
    phoneNumber.dispose();
    super.dispose();
  }
}
