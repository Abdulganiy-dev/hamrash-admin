
import 'package:flutter/material.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

class TemplateViewModel extends BaseViewModel {
  String title = "Template Title";
  late BuildContext context;

  void init(BuildContext context) {
    this.context = context;
  }
}
