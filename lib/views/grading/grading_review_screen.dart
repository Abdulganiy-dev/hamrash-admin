import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hamrash_admin/api/models/class_structure/class_structure.dart';
import 'package:hamrash_admin/api/models/grading/grade_review.dart';
import 'package:hamrash_admin/api/models/grading/grading_numbers.dart';
import 'package:hamrash_admin/api/models/grading/score_column.dart';
import 'package:hamrash_admin/api/models/grading/section_grading.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/core/constants/app_colors.dart';
import 'package:hamrash_admin/core/constants/app_typography.dart';
import 'package:hamrash_admin/core/widgets/app_cards.dart';
import 'package:hamrash_admin/core/widgets/app_divider.dart';
import 'package:hamrash_admin/core/widgets/app_icons.dart';
import 'package:hamrash_admin/core/widgets/app_keyboard_bar.dart';
import 'package:hamrash_admin/core/widgets/app_refresh_scroll_view.dart';
import 'package:hamrash_admin/core/widgets/app_section_action.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/core/widgets/default_scaffold.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/views/grading/grades_screen.dart';
import 'package:hamrash_admin/views/grading/grading_review_view_model.dart';
import 'package:hamrash_admin/views/grading/score_columns_screen.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_bars.dart';
import 'package:hamrash_admin/views/grading/widgets/grading_body.dart';
import 'package:stacked/stacked.dart';

/// 9.39 · Review how one section is graded, and try a score. Nothing typed
/// here is saved. Done returns to the sections list.
class GradingReviewScreen extends StatelessWidget {
  const GradingReviewScreen({
    super.key,
    required this.school,
    required this.section,
  });

  final MemberSchool school;
  final SchoolSection section;

  @override
  Widget build(BuildContext context) =>
      ViewModelBuilder<GradingReviewViewModel>.reactive(
        viewModelBuilder: () =>
            GradingReviewViewModel(school: school, section: section),
        onViewModelReady: (model) => model.load(),
        builder: (context, model, _) {
          final actions = _ReviewActions(model);
          return DefaultScaffold(
            title: 'Review',
            subtitle: section.name,
            centerTitle: true,
            showBackButton: true,
            onBackPressed: () => NavigationService.popScreen(false),
            backgroundColor: AppPalette.linen,
            body: GradingBody(
              loading: model.loading,
              error: model.error,
              onRetry: model.load,
              stateKey: () => 'review',
              content: () => _ReviewView(model: model, actions: actions),
            ),
            bottomNavigationBar: model.loading || model.error != null
                ? null
                : AppKeyboardBar.isKeyboardOpen(context)
                ? const AppKeyboardBar()
                : SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: AppPrimaryButton(
                        height: 52,
                        onPressed: () => NavigationService.popScreen(true),
                        child: const Text('Done'),
                      ),
                    ),
                  ),
          );
        },
      );
}

class _ReviewView extends StatefulWidget {
  const _ReviewView({required this.model, required this.actions});

  final GradingReviewViewModel model;
  final _ReviewActions actions;

  @override
  State<_ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends State<_ReviewView> {
  final _controllers = <String, TextEditingController>{};

  SectionGrading get _grading => widget.model.grading;

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(_ReviewView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncControllers() {
    final ids = {for (final column in _grading.columns) column.id};
    for (final id in _controllers.keys.toList()) {
      if (!ids.contains(id)) {
        _controllers.remove(id)?.dispose();
      }
    }
    for (final column in _grading.columns) {
      _controllers.putIfAbsent(column.id, () {
        final value = (column.maxScore * 0.86).round().clamp(
          0,
          column.maxScore.round(),
        );
        return TextEditingController(
          text: GradingNumbers.format(value.toDouble()),
        );
      });
    }
  }

  Map<String, String> get _scores => {
    for (final column in _grading.columns)
      column.id: _controllers[column.id]?.text ?? '',
  };

  GradeReview get _review =>
      GradeReview.calculate(grading: _grading, scores: _scores);

  @override
  Widget build(BuildContext context) {
    final grading = _grading;
    final review = _review;
    return AppRefreshScrollView.children(
      onRefresh: widget.model.refresh,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppIcon(
                    AppIcons.circleCheck,
                    size: 16,
                    color: LightColors.successSuccessDefault,
                  ),
                  const SizedBox(width: 6),
                  AppText(
                    'Set up · already saved',
                    style: AppTypography.body.copyWith(
                      fontSize: 13,
                      height: 18 / 13,
                      fontWeight: FontWeight.w700,
                      color: LightColors.successSuccessText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              AppText(
                'How ${widget.model.section.name} is graded',
                colorType: AppTextColor.textStrong,
                style: AppTypography.heading(
                  24,
                  lineHeight: 32,
                ).copyWith(letterSpacing: -0.01),
              ),
              const SizedBox(height: 6),
              AppText(
                'Every change was saved as you made it. Nothing else changes '
                'when you leave.',
                style: AppTypography.body.copyWith(
                  fontSize: 14,
                  height: 20 / 14,
                  color: LightColors.textBody,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        AppSectionHeader(
          title: 'Score columns',
          caption: grading.marksLabel,
          action: widget.model.canChange
              ? AppSectionAction(
                  label: 'Change',
                  icon: AppIcons.pencil,
                  onPressed: () => widget.actions.openColumns(context),
                )
              : null,
        ),
        const SizedBox(height: 12),
        ColumnContributionBar(
          columns: grading.columns,
          totalMarks: grading.totalMarks,
        ),
        const SizedBox(height: 28),
        AppSectionHeader(
          title: 'Grades',
          caption:
              '${grading.gradeSystem?.label ?? 'Custom'}, '
              '${grading.grades.length}',
          action: widget.model.canChange
              ? AppSectionAction(
                  label: 'Change',
                  icon: AppIcons.pencil,
                  onPressed: () => widget.actions.openGrades(context),
                )
              : null,
        ),
        const SizedBox(height: 12),
        _MarkedGradeBar(grading: grading, percent: review.percent),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                'Try a score',
                style: AppTypography.subtitle.copyWith(
                  fontSize: 16,
                  color: LightColors.textStrong,
                ),
              ),
              const SizedBox(height: 2),
              AppText(
                'Type other scores and watch the marker move on the grades '
                'bar. Nothing is saved.',
                style: AppTypography.body.copyWith(
                  fontSize: 13,
                  height: 18 / 13,
                  color: LightColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final (i, column) in grading.columns.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ScoreRow(
              column: column,
              controller: _controllers[column.id]!,
              style: columnSegmentStyle(i),
              onChanged: (_) => setState(() {}),
            ),
          ),
        const SizedBox(height: 4),
        const AppDivider(),
        const SizedBox(height: 16),
        _Result(review: review, grading: grading),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// The grade bar with the "86%" tag above where the score lands.
class _MarkedGradeBar extends StatelessWidget {
  const _MarkedGradeBar({required this.grading, required this.percent});

  final SectionGrading grading;
  final int percent;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        height: 28,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const markerWidth = 44.0;
            final left =
                (percent / 100 * constraints.maxWidth - markerWidth / 2).clamp(
                  0.0,
                  constraints.maxWidth - markerWidth,
                );
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: left,
                  bottom: 0,
                  child: _PercentMarker(percent: percent),
                ),
              ],
            );
          },
        ),
      ),
      GradeRangeBar(grading: grading),
    ],
  );
}

class _PercentMarker extends StatelessWidget {
  const _PercentMarker({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 44,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppPalette.stone900,
          borderRadius: BorderRadius.circular(999),
        ),
        child: AppText(
          '$percent%',
          style: AppTypography.body.copyWith(
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w800,
            color: AppPalette.white,
          ),
        ),
      ),
      CustomPaint(
        size: const Size(12, 6),
        painter: _MarkerArrowPainter(color: AppPalette.stone900),
      ),
    ],
  );
}

class _MarkerArrowPainter extends CustomPainter {
  const _MarkerArrowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_MarkerArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.column,
    required this.controller,
    required this.style,
    required this.onChanged,
  });

  final ScoreColumn column;
  final TextEditingController controller;
  final ({Color fill, Color text}) style;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: style.fill,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: AppPalette.stone200),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AppText(
            column.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(
              fontSize: 15,
              height: 20 / 15,
              color: LightColors.textBody,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 112,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppPalette.stone50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppPalette.stone200),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
                    LengthLimitingTextInputFormatter(8),
                  ],
                  onChanged: onChanged,
                  textAlignVertical: TextAlignVertical.center,
                  style: AppTypography.subtitle.copyWith(
                    fontSize: 16,
                    color: LightColors.textStrong,
                  ),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              AppText(
                '/ ${GradingNumbers.format(column.maxScore)}',
                style: AppTypography.body.copyWith(
                  fontSize: 14,
                  color: LightColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Result extends StatelessWidget {
  const _Result({required this.review, required this.grading});

  final GradeReview review;
  final SectionGrading grading;

  @override
  Widget build(BuildContext context) {
    final grade = review.grade;
    final pass = grade?.isPass ?? false;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                review.scoreLine,
                style: AppTypography.body.copyWith(
                  fontSize: 13,
                  height: 18 / 13,
                  color: LightColors.textMuted,
                ),
              ),
              AppText(
                review.percentLabel,
                colorType: AppTextColor.textStrong,
                style: AppTypography.heading(
                  40,
                  lineHeight: 44,
                ).copyWith(letterSpacing: -0.02),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (grade != null)
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppText(
                    grade.remark?.trim().isNotEmpty ?? false
                        ? grade.remark!.trim()
                        : grade.flag,
                    style: AppTypography.subtitle.copyWith(
                      fontSize: 15,
                      color: LightColors.textStrong,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    review.gradeLine,
                    style: AppTypography.body.copyWith(
                      fontSize: 13,
                      height: 18 / 13,
                      fontWeight: FontWeight.w600,
                      color: grade.isPass
                          ? LightColors.successSuccessText
                          : LightColors.errorErrorText,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: pass
                      ? LightColors.primaryPrimaryDefault
                      : LightColors.errorErrorDefault,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AppText(
                  grade.grade,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: AppTypography.heading(
                    26,
                    lineHeight: 32,
                  ).copyWith(color: AppPalette.white),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ReviewActions {
  const _ReviewActions(this.model);

  final GradingReviewViewModel model;

  Future<void> openColumns(BuildContext context) async {
    final changed = await NavigationService.animatedNavigation<bool>(
      screen: ScoreColumnsScreen(school: model.school, section: model.section),
    );
    if (changed == true) await model.markChanged();
  }

  Future<void> openGrades(BuildContext context) async {
    final changed = await NavigationService.animatedNavigation<bool>(
      screen: GradesScreen(school: model.school, section: model.section),
    );
    if (changed == true) await model.markChanged();
  }
}
