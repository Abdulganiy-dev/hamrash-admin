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
import 'package:hamrash_admin/widgets/app_search_field.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/widgets/button/app_button_variants.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:stacked/stacked.dart';

class TeachersView extends StatefulWidget {
  const TeachersView({super.key});
  static const String routeName = '/teachers';

  @override
  State<TeachersView> createState() => _TeachersViewState();
}

class _TeachersViewState extends State<TeachersView> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollController = ScrollController();
  TeachersViewModel? _model;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onScroll() {
    final m = _model;
    if (m == null || !_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      m.loadMore();
    }
  }

  void _openSearch() {
    setState(() => _isSearching = true);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _searchFocus.requestFocus(),
    );
  }

  void _closeSearch(TeachersViewModel model) {
    setState(() => _isSearching = false);
    _searchController.clear();
    model.setSearchQuery('');
    _searchFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<TeachersViewModel>.reactive(
      viewModelBuilder: () => TeachersViewModel(),
      onViewModelReady: (model) {
        _model = model;
        model.init(context);
      },
      builder: (context, model, _) => DefaultScaffold(
        title: null,
        busy: model.busy,

        appBarType: DefaultScaffoldAppBarType.custom,
        customAppBar: _buildHeader(context, model),
        body: Builder(
          builder: (context) {
            return SingleChildScrollView(
              controller: _scrollController,
              child: ScaffoldColumn(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    height:
                        ScaffoldInsets.of(context).bodyTopInset +
                        (_isSearching ? 50 : 15),
                  ),
                  _buildGrid(context, model),
                  if (model.loadingMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TeachersViewModel model) {
    return ClipRect(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final isSearchRow = child.key == const ValueKey('search');
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(isSearchRow ? 0.08 : -0.04, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.centerLeft,
          children: [...previousChildren, ?currentChild],
        ),
        child: _isSearching
            ? _SearchActiveRow(
                key: const ValueKey('search'),
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: model.setSearchQuery,
                onClose: () => _closeSearch(model),
              )
            : _IdleHeaderRow(
                key: const ValueKey('idle'),
                onSearchTap: _openSearch,
                onAddTap: () => _openCreate(context, model),
              ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, TeachersViewModel model) {
    final teachers = model.filteredTeachers;

    if (teachers.isEmpty && !model.busy && !model.isSearchPending) {
      return _EmptyState(isSearching: _searchController.text.isNotEmpty);
    }

    // if (teachers.isEmpty && model.isSearchPending) {
    //   return const _SearchPendingState();
    // }

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.82,
      ),
      itemCount: teachers.length,
      itemBuilder: (context, i) => _TeacherGridItem(
        teacher: teachers[i],
        onTap: () => _openDetail(context, teachers[i], model),
      ),
    );
  }

  void _openCreate(BuildContext context, TeachersViewModel model) {
    NavigationService.animatedNavigation(
      screen: CreateTeacherView(teachersViewModel: model),
    );
  }

  void _openDetail(
    BuildContext context,
    TeacherModel teacher,
    TeachersViewModel model,
  ) {
    NavigationService.animatedNavigation(
      screen: TeacherDetailView(teacher: teacher, teachersViewModel: model),
    );
  }
}

// ─── Idle Header Row ─────────────────────────────────────────────────────────

class _IdleHeaderRow extends StatelessWidget {
  const _IdleHeaderRow({
    super.key,
    required this.onSearchTap,
    required this.onAddTap,
  });

  final VoidCallback onSearchTap;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppHugeIconButton(
            hugeIcon: HugeIcons.strokeRoundedSearch01,
            hugeIconStrokeWidth: 2,
            hugeIconRasterSize: 30,
            foregroundColorType: AppButtonForegroundColor.textInverted,
            onPressed: onSearchTap,
          ),
          Spacer(),
          AppText(
            'Teachers',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          Spacer(),
          AppHugeIconButton(
            hugeIcon: HugeIcons.strokeRoundedAdd01,
            hugeIconStrokeWidth: 2,
            hugeIconRasterSize: 30,
            foregroundColorType: AppButtonForegroundColor.textInverted,
            onPressed: onAddTap,
          ),
        ],
      ),
    );
  }
}

// ─── Search Active Row ────────────────────────────────────────────────────────

class _SearchActiveRow extends StatelessWidget {
  const _SearchActiveRow({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClose,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppHugeIconButton(
          hugeIcon: HugeIcons.strokeRoundedArrowLeft01,
          hugeIconStrokeWidth: 2,
          hugeIconRasterSize: 28,
          foregroundColorType: AppButtonForegroundColor.textInverted,
          onPressed: onClose,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: AppSearchField(
            controller: controller,
            focusNode: focusNode,
            hintText: 'Search teachers…',
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
      ],
    );
  }
}

// ─── Search pending ───────────────────────────────────────────────────────────

class _SearchPendingState extends StatelessWidget {
  const _SearchPendingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          const nameLineHeight = 17.0;
          const nameLines = 2;
          const gap = AppSpacing.sm;
          final maxW = constraints.maxWidth;
          final maxH = constraints.maxHeight;
          final nameBlockHeight = nameLineHeight * nameLines;
          final avatarSize = (maxH - gap - nameBlockHeight).clamp(
            0.0,
            maxW * 0.72,
          );

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TeacherAvatar(teacher: teacher, size: avatarSize),
              const SizedBox(height: gap),
              AppText(
                teacher.fullName,
                textAlign: TextAlign.center,
                maxLines: nameLines,
                overflow: TextOverflow.ellipsis,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                colorType: AppTextColor.textInverted,
              ),
            ],
          );
        },
      ),
    ).hapticFeedback();
  }
}
