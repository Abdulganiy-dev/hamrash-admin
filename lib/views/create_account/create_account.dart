

import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/viewModel/create_account_view_model.dart';
import 'package:hamrash_admin/widgets/step_indicator.dart';
import 'package:stacked/stacked.dart';



class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});
  static String routeName = '/create-account';

  @override
  State<CreateAccount> createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  late CreateAccountViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<CreateAccountViewModel>.reactive(
      viewModelBuilder: () => CreateAccountViewModel(),
      onViewModelReady: (viewModel) {
        this.viewModel = viewModel;
        viewModel.init(context);
      },
      builder: (context, model, _) => DefaultScaffold(
          title:null,
          showBackButton: true,
          onBackPressed: () => Navigator.of(context).pop(),
          busy: viewModel.busy,
          body: ScaffoldColumn(
            children: [
              CreateAccountStepIndicator(currentStep: model.currentStep),
            ],
          )),
    );
  }
}
