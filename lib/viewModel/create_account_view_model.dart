

import 'package:flutter/material.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

class CreateAccountViewModel extends BaseViewModel {
  String title = "Create account";
  late BuildContext context;

  void init(BuildContext context) {
    this.context = context;
  }
}
