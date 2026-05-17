import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/app_colors.dart';
import 'package:hamrash_admin/views/home/home.dart';
import 'package:hamrash_admin/views/more/more_view.dart';
import 'package:hamrash_admin/views/staff/staff_view.dart';
import 'package:hamrash_admin/views/student/student_view.dart';
import 'package:hamrash_admin/widgets/hamrash_tab_bar.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:stacked/stacked.dart';

import 'main_tab_view_model.dart';


class MainTabView extends StatefulWidget {
  const MainTabView({super.key});
  static String routeName = '/main-tab';

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  late MainTabViewModel viewModel;


  static const List<HamrashTabItem> _tabItems = [
    HamrashTabItem(icon: HugeIcon(icon: HugeIcons.strokeRoundedHome04, strokeWidth: 2,)),
    HamrashTabItem(icon: HugeIcon(icon: HugeIcons.strokeRoundedBackpack02, strokeWidth: 2,)),
    HamrashTabItem(icon: HugeIcon(icon: HugeIcons.strokeRoundedUserGroup, strokeWidth: 2,)),
    HamrashTabItem(icon: HugeIcon(icon: HugeIcons.strokeRoundedMore, strokeWidth: 2,)),
  ];

  static const List<Widget> _pages = [
    Home(),
    StudentView(),
    TeachersView(),
    MoreView(),
  ];

  static const double _cardRadius = 34;


  Color _shellColor(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return isLight ? Colors.black : DarkColors.primaryNeutralBlack;
  }

  Color _inactiveIconColor(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return isLight ? LightColors.iconIconMute : DarkColors.primaryNeutralBlack;
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<MainTabViewModel>.reactive(
      viewModelBuilder: () => MainTabViewModel(),
      onViewModelReady: (model) {
        viewModel = model;
        model.init(context);
      },
      builder: (context, model, _) => Scaffold(
        backgroundColor: _shellColor(context),
        body: ClipRRect(
          borderRadius: BorderRadius.circular(_cardRadius),
          child: IndexedStack(
            index: model.currentIndex,
            children: _pages,
          ),
        ),
        bottomNavigationBar: HamrashTabBar(
          items: _tabItems,
          height: 45,
          currentIndex: model.currentIndex,
          onTap: model.setIndex,
          inactiveIconColor: _inactiveIconColor(context),
        ),
      ),
    );
  }
}
