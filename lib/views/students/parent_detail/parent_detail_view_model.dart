import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/api/models/students/parent_profile.dart';
import 'package:hamrash_admin/api/models/students/student_profile.dart';
import 'package:hamrash_admin/api/services/supabase_services/student_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/supabase_refusal.dart';
import 'package:hamrash_admin/core/utils/app_date_format.dart';
import 'package:hamrash_admin/core/utils/phone_format.dart';
import 'package:hamrash_admin/core/widgets/app_alert_dialog.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';
import 'package:hamrash_admin/views/team/widgets/access_card.dart';

/// 9.18 / 9.18a · One parent: their children, details and login. Leaders
/// change the details and issue the login; only the owner and admins cancel an
/// invite, suspend or restore the login, or remove the parent.
///
/// Sheet saves return an error message (null when it worked); confirmed
/// actions throw [AppAlertError] for the confirm sheet to show.
class ParentDetailViewModel extends BaseViewModel {
  ParentDetailViewModel({
    required this.school,
    required this.parentId,
    StudentService? students,
  }) : _students = students ?? locator<StudentService>();

  final MemberSchool school;
  final String parentId;
  final StudentService _students;

  ParentProfile? _parent;
  Object? _error;
  bool _changed = false;
  bool _removed = false;

  ParentProfile get parent => _parent!;
  Object? get error => _error;
  bool get loading => _parent == null && _error == null;

  /// Something was saved, so the page behind reloads.
  bool get changed => _changed;
  bool get removed => _removed;

  bool get canEdit => school.canRunSetup;
  bool get canManageAccess => school.canManageAccess;

  StudentAccess get access {
    final login = parent.login;
    if (login == null) return StudentAccess.notOnApp;
    return switch (login.status.value) {
      'invited' => StudentAccess.codeReady,
      'suspended' => StudentAccess.suspended,
      _ => StudentAccess.onApp,
    };
  }

  bool get canInvite =>
      canEdit && parent.isActive && access == StudentAccess.notOnApp;

  // ───────────────────────── words ─────────────────────────

  /// "Parent of 2 · Pharmacist".
  String get identityMeta {
    final count = parent.children.length;
    final of = count == 0
        ? 'No children yet'
        : 'Parent of $count';
    return [of, ?parent.occupation].join(' · ');
  }

  /// The pill under the name: where their login has got to.
  String get statusLabel => switch (access) {
    StudentAccess.notOnApp => 'Not on app',
    StudentAccess.codeReady => 'Invite pending',
    StudentAccess.onApp => 'On app',
    StudentAccess.suspended => 'Suspended',
  };

  String get phoneLabel => PhoneFormat.nationalDisplay(parent.phone);

  String? get accessCaption {
    final login = parent.login;
    if (login == null) return null;
    return switch (access) {
      StudentAccess.codeReady =>
        'Invited ${AppDateFormat.dayMonth(login.createdAt)}',
      StudentAccess.onApp || StudentAccess.suspended =>
        login.joinedAt == null
            ? null
            : 'Joined ${AppDateFormat.dayMonthYear(login.joinedAt!)}',
      StudentAccess.notOnApp => null,
    };
  }

  /// One app card, "Hamrash Student": parents and students share the family
  /// app. Tapping it invites a parent who isn't on it.
  List<AccessApp> accessApps({VoidCallback? onInvite}) => [
    AccessApp(
      appName: 'Hamrash Student',
      state: switch (access) {
        StudentAccess.notOnApp => AccessState.notOnApp,
        StudentAccess.codeReady => AccessState.codeReady,
        StudentAccess.onApp => AccessState.onApp,
        StudentAccess.suspended => AccessState.suspended,
      },
      onTap: access == StudentAccess.notOnApp ? onInvite : null,
    ),
  ];

  String get rawCode => parent.login?.claimCode ?? '';

  String shareMessage(String code) =>
      'Hi ${parent.firstName}, ${school.name} has added you on Hamrash. Open '
      'the Hamrash student app, sign in with Apple or Google, and enter '
      '${_formatCode(code)}.';

  static String _formatCode(String raw) {
    final code = raw.replaceAll('-', '').toUpperCase();
    return code.length == 8
        ? '${code.substring(0, 4)}-${code.substring(4)}'
        : code;
  }

  String get removeTitle => 'Remove ${parent.displayName}?';

  static const removeMessage =
      'Use this only if they were added by mistake. Their children stay at '
      'the school.';

  List<String> get removeBullets {
    final children = parent.children.length;
    return [
      children == 0
          ? 'Their record is removed'
          : 'Their record and their link to '
                '${children == 1 ? parent.children.first.firstName : '$children children'} '
                'are removed',
      if (parent.login != null) 'Their login stops working',
    ];
  }

  // ───────────────────────── loading ─────────────────────────

  Future<void> load() async {
    _error = null;
    notifyListeners();
    try {
      await _fetch();
    } catch (error, stackTrace) {
      _error = error;
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'ParentDetail.load',
        showErrorModal: false,
      );
    }
    if (!isDisposed) notifyListeners();
  }

  Future<void> refresh() async {
    try {
      await _fetch();
      _error = null;
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: 'ParentDetail.refresh',
        showErrorModal: false,
      );
      rethrow;
    } finally {
      if (!isDisposed) notifyListeners();
    }
  }

  Future<void> _fetch() async {
    _parent = await _students.getParent(
      organizationId: school.id,
      parentId: parentId,
    );
  }

  // ───────────────────────── changes ─────────────────────────

  Future<String?> saveDetails(ParentDetailsChanges changes) => _save(
    () => _students.updateParentDetails(parent: parent, changes: changes),
    "Couldn't save the details. Try again.",
    'ParentDetail.saveDetails',
  );

  Future<({String? code, String? error})> invite() async {
    String? code;
    final error = await _save(() async {
      code = await _students.inviteParent(parentId);
    }, "Couldn't create the invite. Try again.", 'ParentDetail.invite');
    return (code: code, error: error);
  }

  Future<void> cancelInvite() => _act(
    () => _students.cancelInvite(parent.login!.id),
    "Couldn't cancel the invite. Try again.",
  );

  Future<void> setSuspended(bool suspended) => _act(
    () => _students.setSuspended(
      memberId: parent.login!.id,
      suspended: suspended,
    ),
    suspended
        ? "Couldn't suspend access. Try again."
        : "Couldn't restore access. Try again.",
  );

  Future<void> remove() async {
    await _act(
      () => _students.removeParent(parentId),
      "Couldn't remove them. Try again.",
    );
    _removed = true;
  }

  Future<String?> _save(
    Future<void> Function() action,
    String fallback,
    String context,
  ) async {
    try {
      await action();
      _changed = true;
      await _fetch().catchError((_) {});
      return null;
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace: stackTrace,
        context: context,
        showErrorModal: false,
      );
      await _fetch().catchError((_) {});
      return error is SupabaseRefusal ? error.message : fallback;
    } finally {
      if (!isDisposed) notifyListeners();
    }
  }

  Future<void> _act(Future<void> Function() action, String fallback) async {
    final message = await _save(action, fallback, 'ParentDetail.action');
    if (message != null) throw AppAlertError(message);
  }
}
