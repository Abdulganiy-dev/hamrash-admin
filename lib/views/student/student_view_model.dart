import 'package:flutter/material.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

class StudentViewModel extends BaseViewModel {
  String title = "Students";
  late BuildContext context;

  void init(BuildContext context) {
    this.context = context;
  }
}
