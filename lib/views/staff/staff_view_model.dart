import 'package:flutter/material.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

class StaffViewModel extends BaseViewModel {
  String title = "Staff";
  late BuildContext context;

  void init(BuildContext context) {
    this.context = context;
  }
}
