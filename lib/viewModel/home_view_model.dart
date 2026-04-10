


import 'package:flutter/material.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

class HomeViewModel extends BaseViewModel {
  String title = "Home";
  late BuildContext context;

  void init(BuildContext context) {
    this.context = context;
  }
}
