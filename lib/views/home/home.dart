import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/radius_containers.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/viewModel/home_view_model.dart';
import 'package:hamrash_admin/views/home/widgets/home_attendance_greeting.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/cached_network_image_widget.dart';
import 'package:hugeicons/hugeicons.dart';
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
        appBarType: DefaultScaffoldAppBarType.none,
        body: Builder(
          builder: (context) => SingleChildScrollView(
            child: ScaffoldColumn(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: ScaffoldInsets.of(context).bodyTopInset + 50),
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

                _attendanceReportCard().padding(bottom: AppSpacing.md),

                AppText(
                  "Recent Activities",
                  colorType: AppTextColor.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ).padding(bottom: AppSpacing.md),

                AppText(
                  "Quick Actions",
                  colorType: AppTextColor.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ).padding(bottom: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _attendanceReportCard() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final outerColor = isLight
        ? LightColors.backgroundSurfaceMute
        : DarkColors.backgroundSurfaceMute;
    final innerCardColor = isLight
        ? Colors.white
        : DarkColors.backgroundSurfaceLayer;
    final shadowColor = isLight
        ? Colors.black.withOpacity(0.06)
        : Colors.black.withOpacity(0.35);

    final studentsAccent = Colors.blueAccent;
    final staffAccent = Colors.deepOrange;

    return Container(
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: outerColor,
        borderRadius: BorderRadius.circular(AppRadius.xlLg),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _attendanceInnerCard(
                attended: 50,
                total: 100,
                label: 'students',
                icon: HugeIcons.strokeRoundedBackpack02,
                accentColor: studentsAccent,
                cardColor: innerCardColor,
                shadowColor: shadowColor,
              ),
            ),
            SizedBox(width: 5),
            Expanded(
              child: _attendanceInnerCard(
                attended: 30,
                total: 60,
                label: 'staff',
                icon: HugeIcons.strokeRoundedUserGroup,
                accentColor: staffAccent,
                cardColor: innerCardColor,
                shadowColor: shadowColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attendanceInnerCard({
    required int attended,
    required int total,
    required String label,
    required List<List<dynamic>> icon,
    required Color accentColor,
    required Color cardColor,
    required Color shadowColor,
  }) {
    final percent = total == 0 ? 0.0 : (attended / total).clamp(0.0, 1.0);
    final percentLabel = '${(percent * 100).round()}%';

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 18,
            offset: Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(color: shadowColor, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              SizedBox(width: 4),
              Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: AppText(
                  'of $total',
                  colorType: AppTextColor.textMute,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: accentColor.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  String _formattedToday() {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.day}';
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}
