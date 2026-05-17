import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/teacher_model.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/viewModel/teachers_view_model.dart';
import 'package:hamrash_admin/views/staff/create_teacher_view.dart';
import 'package:hamrash_admin/views/staff/teacher_detail_view.dart';
import 'package:hamrash_admin/views/staff/widgets/teacher_avatar.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/widgets/button/app_button_variants.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:stacked/stacked.dart';

class StaffView extends StatefulWidget {
  const StaffView({super.key});
  static const String routeName = '/staff';

  @override
  State<StaffView> createState() => _StaffViewState();
}

class _StaffViewState extends State<StaffView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<TeachersViewModel>.reactive(
      viewModelBuilder: () => TeachersViewModel(),
      onViewModelReady: (model) => model.init(context),
      builder: (context, model, _) => DefaultScaffold(
        title: null,
        busy: model.busy,
        appBarType: DefaultScaffoldAppBarType.none,
        body: Builder(
          builder: (context) {
            final topInset = ScaffoldInsets.of(context).topInset;
            return Column(
              children: [
                SizedBox(height: topInset + 16),
                _buildHeader(context, model),
                const SizedBox(height: AppSpacing.md),
                Expanded(child: _buildGrid(context, model)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TeachersViewModel model) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _SearchBar(
              controller: _searchController,
              onChanged: model.setSearchQuery,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          AppHugeIconButton(
            hugeIcon: HugeIcons.strokeRoundedAdd01,
            hugeIconStrokeWidth: 2,
            hugeIconRasterSize: 24,
            foregroundColorType: AppButtonForegroundColor.textInverted,
            onPressed: () => _openCreate(context, model),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, TeachersViewModel model) {
    final teachers = model.filteredTeachers;

    if (teachers.isEmpty && !model.busy) {
      return _EmptyState(isSearching: _searchController.text.isNotEmpty);
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.78,
      ),
      itemCount: teachers.length,
      itemBuilder: (context, i) => _TeacherGridItem(
        teacher: teachers[i],
        onTap: () => _openDetail(context, teachers[i], model),
      ),
    );
  }

  void _openCreate(BuildContext context, TeachersViewModel model) {
    Navigator.push<void>(
      context,
      NavigationService.generalPageRouteBuilder(
        screen: CreateTeacherView(teachersViewModel: model),
      ),
    );
  }

  void _openDetail(
    BuildContext context,
    TeacherModel teacher,
    TeachersViewModel model,
  ) {
    Navigator.push<void>(
      context,
      NavigationService.generalPageRouteBuilder(
        screen: TeacherDetailView(
          teacher: teacher,
          teachersViewModel: model,
        ),
      ),
    );
  }
}

// ─── Search Bar ──────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: LightColors.strokeColourStrokeMild.withValues(alpha: 0.5),
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search teachers…',
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: LightColors.textTextMute,
              ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: LightColors.textTextMute,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isSearching});

  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedUserGroup,
            size: 48,
            strokeWidth: 1.5,
            color: LightColors.textTextMute,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppText(
            isSearching ? 'No teachers found' : 'No teachers yet',
            colorType: AppTextColor.textInverted,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          const SizedBox(height: AppSpacing.xs),
          AppText(
            isSearching
                ? 'Try a different search term'
                : 'Tap + to add your first teacher',
            colorType: AppTextColor.textMute,
            fontSize: 13,
          ),
        ],
      ),
    );
  }
}

// ─── Grid Item ───────────────────────────────────────────────────────────────

class _TeacherGridItem extends StatelessWidget {
  const _TeacherGridItem({required this.teacher, required this.onTap});

  final TeacherModel teacher;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.maxWidth * 0.72;
              return TeacherAvatar(teacher: teacher, size: size);
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          AppText(
            teacher.fullName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            colorType: AppTextColor.textInverted,
          ),
        ],
      ),
    ).hapticFeedback();
  }
}
