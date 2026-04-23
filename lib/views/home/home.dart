import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/viewModel/home_view_model.dart';
import 'package:hamrash_admin/views/home/widgets/home_attendance_greeting.dart';
import 'package:hamrash_admin/widgets/app_cards.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/cached_network_image_widget.dart';
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
                _recentActivitiesCard().padding(bottom: AppSpacing.md),

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

  Widget _recentActivitiesCard() {
    return AppSurfaceCard(
      padding: EdgeInsets.all(5),
      child: ListView.builder(
        itemCount: viewModel.recentActivities.length,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (context, index) => AppElevatedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                viewModel.recentActivities[index].title,
                colorType: AppTextColor.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ],
          ),
        ),
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
              child: AppElevatedCard(
                child: _attendanceStats(
                  attended: 50,
                  total: 100,
                  label: 'students',
                  accentColor: Colors.blueAccent,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: AppElevatedCard(
                child: _attendanceStats(
                  attended: 30,
                  total: 60,
                  label: 'staff',
                  accentColor: Colors.deepOrange,
                ),
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
  }) {
    final percent = total == 0 ? 0.0 : (attended / total).clamp(0.0, 1.0);

    return Column(
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
    );
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}
