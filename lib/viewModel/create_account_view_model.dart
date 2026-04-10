

import 'package:flutter/material.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';
import 'package:hamrash_admin/widgets/step_indicator.dart';

class CreateAccountViewModel extends BaseViewModel {
  String title = "Create account";
  late BuildContext context;
  CreateAccountStep _currentStep = CreateAccountStep.name;
  CreateAccountStep get currentStep => _currentStep;

  void init(BuildContext context) {
    this.context = context;
  }
}
