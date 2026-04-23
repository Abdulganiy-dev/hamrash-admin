import 'package:flutter/material.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

class MoreViewModel extends BaseViewModel {
  String title = "More";
  late BuildContext context;

  void init(BuildContext context) {
    this.context = context;
  }
}
