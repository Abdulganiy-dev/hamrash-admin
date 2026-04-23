


import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/admin_profile_model.dart';
import 'package:hamrash_admin/api/services/supabase_services/admin_profile_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';
import 'package:hamrash_admin/views/sign_in/sign_in.dart';

class HomeViewModel extends BaseViewModel {
  String title = "Home";
  late BuildContext context;
  final adminProfileService = locator<AdminProfileService>();
  late AdminProfileModel adminProfile;

  String? get fullName {
    return adminProfile.fullName;
  }

  String? get clerkId {
    try {
      final clerkAuth = ClerkAuth.of(context);
      return clerkAuth.user?.id;
    } catch (_) {
      return null;
    }
  }


  void init(BuildContext context) {
    this.context = context;
    fetchAdminProfile();
  }


  Future<void> fetchAdminProfile() async {
    if (clerkId == null) {
      Navigator.of(context).pushReplacementNamed(SignIn.routeName);
      return;
    }
    final profile = adminProfileService.getAdminProfileByClerkId(clerkId!);
    if (profile == null) {
      Navigator.of(context).pushReplacementNamed(SignIn.routeName);
      return;
    }
    adminProfile = profile;
  }



}
