import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/viewModel/home_view_model.dart';
import 'package:hamrash_admin/views/home/widgets/home_attendance_greeting.dart';
import 'package:hamrash_admin/widgets/app_cards.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/button/app_button.dart';
import 'package:hamrash_admin/widgets/button/app_button_types.dart';
import 'package:hamrash_admin/widgets/cached_network_image_widget.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

class Home extends StatefulWidget {
  const Home({super.key});
  static String routeName = '/home';

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HomeViewModel>.reactive(
      viewModelBuilder: () => HomeViewModel(),
      onViewModelReady: (viewModel) {
        this.viewModel = viewModel;
        viewModel.init(context);
      },
      builder: (context, model, _) => DefaultScaffold(
        title: null,
        busy: viewModel.busy,

        appBarType: DefaultScaffoldAppBarType.standard,
        body: Builder(
          builder: (context) => SingleChildScrollView(
            child: ScaffoldColumn(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: ScaffoldInsets.of(context).bodyTopInset + 15),
                CachedNetworkImageWidget(
                  imageUrl: viewModel.profileImageUrl ?? '',
                  width: 100,
                  height: 100,
                  borderRadius: 100,
                ).padding(bottom: AppSpacing.md),
                HomeAttendanceGreeting(
                  greeting: getGreeting(),
                  fullName: viewModel.fullName ?? '',
                ).padding(bottom: AppSpacing.md),

                _attendanceReportCard().padding(bottom: AppSpacing.lg),

                Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedClock01,
                      size: 20,
                      strokeWidth: 2,
                      color: LightColors.textTextInverted,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    AppText(
                      "Recent Activities",
                      colorType: AppTextColor.textInverted,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                    Spacer(),

                    GestureDetector(
                      onTap: () {},
                      child: Row(
                        children: [
                          AppText(
                            "View All",
                            colorType: AppTextColor.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                      
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowRight01,
                            size: 20,
                            strokeWidth: 2,
                            color: LightColors.textTextPrimary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ).padding(bottom: AppSpacing.md),
                _recentActivitiesCard().padding(bottom: AppSpacing.md),

                Row(
                  children: [
                       HugeIcon(
                      icon: HugeIcons.strokeRoundedDashboardCircleSettings,
                      size: 20,
                      strokeWidth: 2,
                      color: LightColors.textTextInverted,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    AppText(
                      "Quick Actions",
                      colorType: AppTextColor.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    )
                  ],
                ).padding(bottom: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _recentActivitiesCard() {
    return AppSurfaceCard(
      padding: EdgeInsets.all(5),
      child: Column(
        children: List.generate(viewModel.recentActivities.length, (index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == viewModel.recentActivities.length - 1
                  ? 0
                  : AppSpacing.sm,
            ),
            child: AppElevatedCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          viewModel.recentActivities[index].title,
                          colorType: AppTextColor.textInverted,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: AppSpacing.xs),
                        AppText(
                          _formatRecentActivityDate(
                            viewModel.recentActivities[index].date,
                          ),
                          colorType: AppTextColor.textMute,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ],
                    ),
                  ),
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    size: 18,
                    strokeWidth: 2,
                    color: LightColors.textTextMute,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _attendanceReportCard() {
    return AppSurfaceCard(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _attendanceStats(
                attended: 50,
                total: 100,
                label: 'students',
                accentColor: Colors.orange,
                icon: HugeIcons.strokeRoundedBackpack02,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: _attendanceStats(
                attended: 30,
                total: 60,
                label: 'staff',
                accentColor: Colors.purple,
                icon: HugeIcons.strokeRoundedUserGroup,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attendanceStats({
    required int attended,
    required int total,
    required String label,
    required Color accentColor,
    required List<List<dynamic>> icon,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return AppElevatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(icon: icon, size: 30, strokeWidth: 2, color: accentColor),
          SizedBox(height: AppSpacing.xs),
          AppText(
            _capitalize(label),
            colorType: AppTextColor.textMute,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppText(
                '$attended',
                colorType: AppTextColor.textInverted,
                fontWeight: FontWeight.w600,
                fontSize: 20,
                height: 1.0,
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: AppText(
                  'of $total',
                  colorType: AppTextColor.textMute,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  String _formatRecentActivityDate(DateTime date) {
    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final dayDifference = normalizedNow.difference(normalizedDate).inDays;

    if (dayDifference == 0) return 'Today';
    if (dayDifference == 1) return 'Yesterday';
    return DateFormat('d MMM yyyy').format(date);
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}
