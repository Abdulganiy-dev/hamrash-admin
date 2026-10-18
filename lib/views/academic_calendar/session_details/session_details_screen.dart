import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/core/bottomSheets/app_confirm_sheet.dart';
import 'package:hamrash_admin/core/bottomSheets/app_sheet.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/button/app_button.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/core/widgets/load_error_view.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/views/academic_calendar/session_details/session_details_view_model.dart';
import 'package:hamrash_admin/views/academic_calendar/session_details/widgets/closed_session_note.dart';
import 'package:hamrash_admin/views/academic_calendar/session_details/widgets/last_session_card.dart';
import 'package:hamrash_admin/views/academic_calendar/widgets/session_sheets.dart';
import 'package:hamrash_admin/views/academic_calendar/widgets/session_skeletons.dart';
import 'package:hamrash_admin/views/academic_calendar/widgets/session_summary_card.dart';
import 'package:hamrash_admin/views/academic_calendar/widgets/session_terms_section.dart';
import 'package:stacked/stacked.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';

/// 4.1–4.8 · A saved session. Pops `true` when something was saved, closed,
/// reopened or removed, so the sessions list reloads.
class SessionDetailsScreen extends StatelessWidget {
  const SessionDetailsScreen({
    super.key,
    required this.school,
    required this.sessionId,
  });

  final MemberSchool school;
  final String sessionId;

  @override
  Widget build(BuildContext context) =>
      ViewModelBuilder<SessionDetailsViewModel>.reactive(
        viewModelBuilder: () =>
            SessionDetailsViewModel(school: school, sessionId: sessionId),
        onViewModelReady: (model) => model.load(),
        builder: (context, model, _) => DefaultScaffold(
          title: model.session == null
              ? 'Session'
              : '${model.draft.name} session',
          showBackButton: true,
          onBackPressed: () => NavigationService.popScreen(model.changed),
          backgroundColor: AppPalette.linen,
          body: model.error != null
              ? LoadErrorView(onRetry: model.load)
              : model.loading
              ? const _Loading()
              : _Body(model: model),
          bottomNavigationBar: model.hasChanges && !model.readOnly
              ? _SaveBar(model: model)
              : null,
        ),
      );
}

class _Body extends StatelessWidget {
  const _Body({required this.model});

  final SessionDetailsViewModel model;

  @override
  Widget build(BuildContext context) {
    final session = model.session!;
    final toClose = model.sessionToClose;
    return SingleChildScrollView(
      child: Builder(
        builder: (context) => ScaffoldColumn(
          children: [
            SizedBox(height: ScaffoldInsets.of(context).bodyTopInset),
            SessionSummaryCard(
              label: model.label,
              model: model,
              caption: model.caption,
              readOnly: session.isClosed,
              onEdit: model.readOnly ? null : () => _editSession(context),
            ),
            const SizedBox(height: 8),
            SessionTermsSection(
              model: model,
              onAddTerm: model.readOnly ? null : () => _editTerm(context, null),
              onOpenTerm: model.readOnly
                  ? null
                  : (index) => _editTerm(context, index),
            ),
            if (model.hasChanges && model.problem != null)
              _Message(model.problem!),
            if (model.saveError case final message?) _Message(message),
            if (toClose != null) ...[
              const SizedBox(height: 24),
              LastSessionCard(
                session: toClose,
                onClose: () => _confirmClose(context),
              ),
            ],
            if (session.isClosed) ...[
              const SizedBox(height: 24),
              ClosedSessionNote(
                sessionName: session.name,
                onReopen: model.canReopen
                    ? () => _confirmReopen(context)
                    : null,
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _editSession(BuildContext context) => Navigator.of(context).push<void>(
    AppSheetRoute<void>(
      size: AppSheetSize.floating,
      child: EditSessionSheet(
        model: model,
        showRemove: true,
        removeBlockedReason: model.removeBlockedReason,
        onRemove: () => _confirmRemove(context),
      ),
    ),
  );

  void _editTerm(BuildContext context, int? index) =>
      Navigator.of(context).push<void>(
        AppSheetRoute<void>(
          size: AppSheetSize.floating,
          child: EditTermSheet(model: model, index: index),
        ),
      );

  Future<void> _confirmClose(BuildContext context) async {
    final toClose = model.sessionToClose!;
    final closed = await AppConfirmSheet.show(
      context,
      icon: AppSvgIcons.lock,
      tone: AppBadgeTone.info,
      title: 'Close ${toClose.name}?',
      message:
          "Last year's records are kept as they are. Its terms, classes, "
          "subjects and results can't be changed, nothing new can be added "
          'to it, and only the owner can reopen it.',
      confirmLabel: 'Close ${toClose.name}',
      cancelLabel: 'Not now',
      onConfirm: model.closeSessionToClose,
    );
    if (closed == true) AppToast.show('${toClose.name} is closed');
  }

  Future<void> _confirmReopen(BuildContext context) async {
    final name = model.session!.name;
    final reopened = await AppConfirmSheet.show(
      context,
      icon: AppSvgIcons.lockOpen,
      tone: AppBadgeTone.warning,
      title: 'Reopen $name?',
      message:
          'Its terms, classes, subjects and results can be changed again '
          'until it is closed.',
      confirmLabel: 'Reopen $name',
      onConfirm: model.reopen,
    );
    if (reopened == true) AppToast.show('$name is open again');
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final name = model.session!.name;
    final removed = await AppConfirmSheet.show(
      context,
      icon: AppSvgIcons.trash2,
      isDestructive: true,
      title: 'Remove $name?',
      message: 'The session and its terms will be removed for good.',
      confirmLabel: 'Remove session',
      onConfirm: model.deleteSession,
    );
    if (removed == true) {
      AppToast.show('$name removed');
      NavigationService.popScreen(true);
    }
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: AppText(
      text,
      variant: AppTextVariant.body,
      style: const TextStyle(color: LightColors.errorErrorText),
    ),
  );
}

/// Save changes, with Undo under it, while the page has unsaved edits.
class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.model});

  final SessionDetailsViewModel model;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppPrimaryButton(
            size: AppButtonSize.large,
            isLoading: model.saving,
            loadingText: 'Saving…',
            isDisabled: model.problem != null,
            onPressed: () async {
              if (await model.save()) AppToast.show('Session saved');
            },
            child: const Text('Save changes'),
          ),
          AppButton(
            type: AppButtonType.text,
            text: 'Undo changes',
            isDisabled: model.saving,
            onPressed: model.discardChanges,
          ),
        ],
      ),
    ),
  );
}

/// [SessionDetailsSkeleton] where the page's content starts.
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const NeverScrollableScrollPhysics(),
    child: Builder(
      builder: (context) => ScaffoldColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: ScaffoldInsets.of(context).bodyTopInset),
          const SessionDetailsSkeleton(),
        ],
      ),
    ),
  );
}
