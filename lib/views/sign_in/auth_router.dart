import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hamrash_admin/api/services/supabase_services/admin_profile_service.dart';
import 'package:hamrash_admin/database/realm_service.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/views/create_account/create_account.dart';
import 'package:hamrash_admin/views/home/home.dart';

class AuthRouter extends StatefulWidget {
  const AuthRouter({super.key});

  @override
  State<AuthRouter> createState() => _AuthRouterState();
}

class _AuthRouterState extends State<AuthRouter> {
  late final AdminProfileService adminProfileService;
  late final RealmService realmService;

  @override
  void initState() {
    super.initState();
    adminProfileService = locator<AdminProfileService>();
    realmService = locator<RealmService>();

    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    final clerkAuth = ClerkAuth.of(context);
    final clerkId = clerkAuth.user?.id;

    if (clerkId == null) {
      _navigateTo(hasAccount: false);
      return;
    }

    final adminProfile = await adminProfileService.fetchAdminProfileByClerkId(
      clerkId,
    );
    if (adminProfile == null) {
      _navigateTo(hasAccount: false);
      return;
    }
    _navigateTo(hasAccount: true);
    return;
  }

  void _navigateTo({required bool hasAccount}) {
    if (!mounted) return;

    final route = hasAccount ? Home.routeName : CreateAccount.routeName;
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return const DefaultScaffold(
      title: "",
      busy: true,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
