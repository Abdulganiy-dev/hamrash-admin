import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/teacher_model.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/viewModel/teachers_view_model.dart';
import 'package:hamrash_admin/views/staff/create_teacher_view.dart';
import 'package:hamrash_admin/views/staff/widgets/teacher_avatar.dart';
import 'package:hamrash_admin/widgets/app_cards.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/widgets/button/app_button_variants.dart';
import 'package:hugeicons/hugeicons.dart';

class TeacherDetailView extends StatefulWidget {
  const TeacherDetailView({
    super.key,
    required this.teacher,
    required this.teachersViewModel,
  });

  final TeacherModel teacher;
  final TeachersViewModel teachersViewModel;

  @override
  State<TeacherDetailView> createState() => _TeacherDetailViewState();
}

class _TeacherDetailViewState extends State<TeacherDetailView> {
  late TeacherModel _teacher;

  @override
  void initState() {
    super.initState();
    _teacher = widget.teacher;
  }

  void _openEdit() {
    Navigator.push<TeacherModel>(
      context,
      NavigationService.generalPageRouteBuilder(
        screen: CreateTeacherView(
          existing: _teacher,
          teachersViewModel: widget.teachersViewModel,
        ),
      ),
    ).then((updated) {
      if (updated != null && mounted) {
        setState(() => _teacher = updated);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultScaffold(
      title: "Teacher Details",
      showBackButton: true,
      actions: [
        AppHugeIconButton(
          hugeIcon: HugeIcons.strokeRoundedPencilEdit01,
          hugeIconStrokeWidth: 2,
          hugeIconRasterSize: 30,
          foregroundColorType: AppButtonForegroundColor.textInverted,
          onPressed: _openEdit,
        ),
      ],
      appBarType: DefaultScaffoldAppBarType.standard,
      body: Builder(
        builder: (context) => SingleChildScrollView(
          child: ScaffoldColumn(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: ScaffoldInsets.of(context).bodyTopInset + 15),
              _AvatarSection(teacher: _teacher),
              const SizedBox(height: AppSpacing.xl),
              if (_hasContact) ...[
                _SectionLabel(label: 'Contact'),
                const SizedBox(height: AppSpacing.sm),
                AppSurfaceCard(
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    children: [
                      if (_teacher.email != null)
                        _InfoRow(
                          icon: HugeIcons.strokeRoundedMail01,
                          label: 'Email',
                          value: _teacher.email!,
                        ),
                      if (_teacher.email != null && _teacher.phone != null)
                        const _RowDivider(),
                      if (_teacher.phone != null)
                        _InfoRow(
                          icon: HugeIcons.strokeRoundedSmartPhone01,
                          label: 'Phone',
                          value: _teacher.phone!,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (_hasPersonal) ...[
                _SectionLabel(label: 'Personal'),
                const SizedBox(height: AppSpacing.sm),
                AppSurfaceCard(
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    children: [
                      if (_teacher.gender != null)
                        _InfoRow(
                          icon: HugeIcons.strokeRoundedUser,
                          label: 'Gender',
                          value: _capitalize(_teacher.gender!),
                        ),
                      if (_teacher.gender != null && _teacher.state != null)
                        const _RowDivider(),
                      if (_teacher.state != null)
                        _InfoRow(
                          icon: HugeIcons.strokeRoundedLocation01,
                          label: 'State',
                          value: _teacher.state!,
                        ),
                      if (_teacher.state != null && _teacher.address != null)
                        const _RowDivider(),
                      if (_teacher.address != null)
                        _InfoRow(
                          icon: HugeIcons.strokeRoundedHome01,
                          label: 'Address',
                          value: _teacher.address!,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              _SectionLabel(label: 'Status'),
              const SizedBox(height: AppSpacing.sm),
              AppSurfaceCard(
                padding: const EdgeInsets.all(5),
                child: _InfoRow(
                  icon: _teacher.isActive
                      ? HugeIcons.strokeRoundedCheckmarkCircle01
                      : HugeIcons.strokeRoundedCancelCircle,
                  label: 'Account',
                  value: _teacher.isActive ? 'Active' : 'Inactive',
                  valueColor: _teacher.isActive
                      ? const Color(0xFF26A69A)
                      : LightColors.errorErrorDefault,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasContact =>
      _teacher.email != null || _teacher.phone != null;

  bool get _hasPersonal =>
      _teacher.gender != null ||
      _teacher.state != null ||
      _teacher.address != null;

  String _capitalize(String s) =>
      s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : s;
}

// ─── Avatar + Name ────────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({required this.teacher});

  final TeacherModel teacher;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          TeacherAvatar(teacher: teacher, size: 100),
          const SizedBox(height: AppSpacing.md),
          AppText(
            teacher.fullName,
            fontWeight: FontWeight.w700,
            fontSize: 22,
            colorType: AppTextColor.textInverted,
            textAlign: TextAlign.center,
          ),
          if (teacher.email != null) ...[
            const SizedBox(height: AppSpacing.xs),
            AppText(
              teacher.email!,
              colorType: AppTextColor.textMute,
              fontSize: 14,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return AppText(
      label,
      colorType: AppTextColor.textMute,
      fontWeight: FontWeight.w800,
      fontSize: 12,
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final List<List<dynamic>> icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return AppElevatedCard(
      child: Row(
        children: [
          HugeIcon(
            icon: icon,
            size: 18,
            strokeWidth: 1.8,
            color: LightColors.textTextMute,
          ),
          const SizedBox(width: AppSpacing.sm),
          AppText(label, colorType: AppTextColor.textMute, fontSize: 13),
          const Spacer(),
          Flexible(
            child: valueColor != null
                ? AppText(
                    value,
                    color: valueColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : AppText(
                    value,
                    colorType: AppTextColor.textInverted,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Row Divider ──────────────────────────────────────────────────────────────

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Divider(
        height: AppSpacing.xs,
        color: LightColors.strokeColourStrokeMild.withValues(alpha: 0.4),
      ),
    );
  }
}
