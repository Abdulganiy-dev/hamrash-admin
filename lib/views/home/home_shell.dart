import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/core/bottomSheets/app_action_sheet.dart';
import 'package:hamrash_admin/core/widgets/app_list_row.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/navigation/app_tab_bar.dart';
import 'package:hamrash_admin/core/widgets/navigation/app_tab_shell.dart';
import 'package:hamrash_admin/views/home/home_screen.dart';
import 'package:hamrash_admin/views/more/more_screen.dart';
import 'package:hamrash_admin/core/widgets/app_svg_icon.dart';

/// The signed-in app for one school: Home, People, Fees and More. People and
/// Fees aren't built yet; their tabs say so.
class HomeShell extends StatelessWidget {
  const HomeShell({
    super.key,
    required this.school,
    required this.userName,
    required this.email,
    required this.onSignOut,
    required this.onOpenSchoolDetails,
    this.userImageUrl,
    this.onSwitchSchool,
  });

  final MemberSchool school;
  final String userName;
  final String email;
  final String? userImageUrl;
  final VoidCallback onSignOut;
  final VoidCallback onOpenSchoolDetails;

  /// Null when this is their only school.
  final VoidCallback? onSwitchSchool;

  static const _comingSoon = {1: 'People', 2: 'Fees'};

  void _openAccount(BuildContext context, String name, String? photoUrl) =>
      AppActionSheet.show(
        context,
        title: name,
        subtitle: '${school.rolesLabel} · ${school.name}',
        leading: AppLeadingPicture(
          leading: AppListLeading.network(photoUrl ?? '', name: name),
          size: 44,
        ),
        groups: [
          if (onSwitchSchool != null)
            [
              AppSheetAction(
                label: 'Switch school',
                icon: AppSvgIcons.arrowLeftRight,
                onTap: onSwitchSchool!,
              ),
            ],
          [
            AppSheetAction(
              label: 'Sign out',
              icon: AppSvgIcons.logOut,
              isDestructive: true,
              onTap: onSignOut,
            ),
          ],
        ],
      );

  @override
  Widget build(BuildContext context) => AppTabShell(
    canSelect: (index) {
      final name = _comingSoon[index];
      if (name == null) return true;
      AppToast.show('$name is coming soon');
      return false;
    },
    tabs: [
      AppTab(
        item: const AppTabItem(
          icon: AppSvgIcons.house,
          activeIcon: AppSvgIcons.house500,
          label: 'Home',
        ),
        builder: (context) => HomeScreen(
          // A new school, or its details changed: load again.
          key: ValueKey('${school.id}/${school.organization.updatedAt}'),
          school: school,
          userName: userName,
          userImageUrl: userImageUrl,
          onAvatarTap: (name, photoUrl) =>
              _openAccount(context, name, photoUrl),
          onOpenSchoolDetails: onOpenSchoolDetails,
        ),
      ),
      for (final MapEntry(value: label) in _comingSoon.entries)
        AppTab(
          item: AppTabItem(
            icon: label == 'People' ? AppSvgIcons.users : AppSvgIcons.wallet,
            label: label,
          ),
          builder: (_) => const SizedBox.shrink(),
        ),
      AppTab(
        item: const AppTabItem(icon: AppSvgIcons.layoutGrid, label: 'More'),
        builder: (context) => MoreScreen(
          key: ValueKey('more/${school.id}/${school.organization.updatedAt}'),
          school: school,
          userName: userName,
          userImageUrl: userImageUrl,
          onAvatarTap: () => _openAccount(context, userName, userImageUrl),
          onSignOut: onSignOut,
          onOpenSchoolDetails: onOpenSchoolDetails,
          onSwitchSchool: onSwitchSchool,
        ),
      ),
    ],
  );
}
