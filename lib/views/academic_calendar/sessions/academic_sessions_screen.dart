import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/academic_calendar/academic_session.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_empty_state.dart';
import 'package:hamrash_admin/core/widgets/app_list_row.dart';
import 'package:hamrash_admin/core/widgets/app_refresh_scroll_view.dart';
import 'package:hamrash_admin/core/widgets/app_spinner.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/core/widgets/load_error_view.dart';
import 'package:hamrash_admin/core/widgets/navigation/app_nav_button.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/views/academic_calendar/create_session/create_session_screen.dart';
import 'package:hamrash_admin/views/academic_calendar/session_details/session_details_screen.dart';
import 'package:hamrash_admin/views/academic_calendar/sessions/academic_sessions_view_model.dart';
import 'package:hamrash_admin/views/academic_calendar/sessions/widgets/current_session_card.dart';
import 'package:hamrash_admin/views/academic_calendar/sessions/widgets/session_dates.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:stacked/stacked.dart';

/// 4.0 / 4.0a · Academic sessions, from the More tab. Pops `true` when a
/// session was added or changed, so the More tab refreshes its tile.
class AcademicSessionsScreen extends StatefulWidget {
  const AcademicSessionsScreen({super.key, required this.school});

  final MemberSchool school;

  @override
  State<AcademicSessionsScreen> createState() => _AcademicSessionsScreenState();
}

class _AcademicSessionsScreenState extends State<AcademicSessionsScreen> {
  bool _changed = false;

  @override
  Widget build(BuildContext context) =>
      ViewModelBuilder<AcademicSessionsViewModel>.reactive(
        viewModelBuilder: () =>
            AcademicSessionsViewModel(school: widget.school),
        onViewModelReady: (model) => model.load(),
        builder: (context, model, _) => DefaultScaffold(
          title: 'Academic sessions',
          showBackButton: true,
          onBackPressed: () => NavigationService.popScreen(_changed),
          backgroundColor: AppPalette.linen,
          actions: [
            if (model.canCreate && !model.isEmpty)
              AppNavIconButton(
                icon: LucideIcons.plus,
                semanticLabel: 'New session',
                onPressed: () => _create(model),
              ),
          ],
          body: model.error != null
              ? LoadErrorView(onRetry: model.load)
              : model.loading
              ? const Center(child: AppSpinner())
              : model.isEmpty
              ? AppEmptyState(
                  icon: LucideIcons.calendar,
                  title: 'No academic sessions yet',
                  subtitle: model.canCreate
                      ? 'Create the first session to set its dates and terms.'
                      : 'The school leaders will add the first session.',
                  actionLabel: model.canCreate ? 'Create session' : null,
                  onAction: model.canCreate ? () => _create(model) : null,
                )
              : _List(model: model, onOpen: (s) => _open(model, s)),
        ),
      );

  Future<void> _create(AcademicSessionsViewModel model) async {
    final created = await NavigationService.animatedNavigation<bool>(
      screen: CreateSessionScreen(
        organizationId: widget.school.id,
        startYear: model.nextStartYear,
      ),
    );
    if (created == true) await _reload(model);
  }

  Future<void> _open(
    AcademicSessionsViewModel model,
    AcademicSession session,
  ) async {
    final changed = await NavigationService.animatedNavigation<bool>(
      screen: SessionDetailsScreen(
        school: widget.school,
        sessionId: session.id,
      ),
    );
    if (changed == true) await _reload(model);
  }

  Future<void> _reload(AcademicSessionsViewModel model) async {
    _changed = true;
    await model.refresh().catchError((_) {});
  }
}

class _List extends StatelessWidget {
  const _List({required this.model, required this.onOpen});

  final AcademicSessionsViewModel model;
  final ValueChanged<AcademicSession> onOpen;

  @override
  Widget build(BuildContext context) {
    final current = model.current;
    final others = model.others;
    return AppRefreshScrollView.children(
      onRefresh: model.refresh,
      children: [
        if (current != null) ...[
          const AppSectionHeader(title: 'Current session'),
          const SizedBox(height: 12),
          CurrentSessionCard(session: current, onTap: () => onOpen(current)),
          const SizedBox(height: 24),
        ],
        if (others.isNotEmpty) ...[
          AppSectionHeader(
            title: current == null ? 'Sessions' : 'Other sessions',
            trailing: AppText(
              others.length == 1 ? '1 session' : '${others.length} sessions',
              style: AppTypography.caption.copyWith(
                fontSize: 13,
                color: AppPalette.stone500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final session in others) ...[
            AppListRow(
              title: session.name,
              subtitle:
                  '${sessionDates(session.dates)} · ${session.terms.length} terms',
              badge: _badge(model.statusOf(session)),
              onTap: () => onOpen(session),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  static AppBadge? _badge(SessionStatus status) => switch (status) {
    SessionStatus.current => null,
    SessionStatus.upcoming => AppBadge(status.label, tone: AppBadgeTone.info),
    SessionStatus.toClose => AppBadge(status.label, tone: AppBadgeTone.warning),
    SessionStatus.open || SessionStatus.closed => AppBadge(status.label),
  };
}
