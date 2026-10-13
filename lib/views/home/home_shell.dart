import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/organization_models/member_school.dart';
import 'package:hamrash_admin/core/bottomSheets/app_action_sheet.dart';
import 'package:hamrash_admin/core/widgets/app_list_row.dart';
import 'package:hamrash_admin/core/widgets/app_toast.dart';
import 'package:hamrash_admin/core/widgets/navigation/app_tab_bar.dart';
import 'package:hamrash_admin/core/widgets/navigation/app_tab_shell.dart';
import 'package:hamrash_admin/views/home/home_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The signed-in app for one school: Home, People, Fees and More. Only Home
/// is built so far; the other tabs say so.
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

  static const _comingSoon = {1: 'People', 2: 'Fees', 3: 'More'};

  void _openAccount(BuildContext context) => AppActionSheet.show(
    context,
    title: userName,
    subtitle: '${school.rolesLabel} · ${school.name}',
    leading: AppLeadingPicture(
      leading: AppListLeading.network(userImageUrl ?? '', name: userName),
      size: 44,
    ),
    groups: [
      if (onSwitchSchool != null)
        [
          AppSheetAction(
            label: 'Switch school',
            icon: LucideIcons.arrowLeftRight,
            onTap: onSwitchSchool!,
          ),
        ],
      [
        AppSheetAction(
          label: 'Sign out',
          icon: LucideIcons.logOut,
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
          icon: LucideIcons.house,
          activeIcon: LucideIcons.house500,
          label: 'Home',
        ),
        builder: (context) => HomeScreen(
          // A new school, or its details changed: load again.
          key: ValueKey('${school.id}/${school.organization.updatedAt}'),
          school: school,
          userName: userName,
          userImageUrl: userImageUrl,
          onAvatarTap: () => _openAccount(context),
          onOpenSchoolDetails: onOpenSchoolDetails,
        ),
      ),
      for (final MapEntry(value: label) in _comingSoon.entries)
        AppTab(
          item: AppTabItem(
            icon: switch (label) {
              'People' => LucideIcons.users,
              'Fees' => LucideIcons.wallet,
              _ => LucideIcons.layoutGrid,
            },
            label: label,
          ),
          builder: (_) => const SizedBox.shrink(),
        ),
    ],
  );
}
