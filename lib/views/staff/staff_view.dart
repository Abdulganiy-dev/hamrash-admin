import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:stacked/stacked.dart';

import 'staff_view_model.dart';

class StaffView extends StatefulWidget {
  const StaffView({super.key});
  static String routeName = '/staff';

  @override
  State<StaffView> createState() => _StaffViewState();
}

class _StaffViewState extends State<StaffView> {
  late StaffViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<StaffViewModel>.reactive(
      viewModelBuilder: () => StaffViewModel(),
      onViewModelReady: (viewModel) {
        this.viewModel = viewModel;
        viewModel.init(context);
      },
      builder: (context, model, _) => DefaultScaffold(
        title: viewModel.title,
        busy: viewModel.busy,
        appBarType: DefaultScaffoldAppBarType.none,
        body: Builder(
          builder: (context) => ScaffoldColumn(
            children: [
              SizedBox(height: ScaffoldInsets.of(context).bodyTopInset),
              // content
            ],
          ),
        ),
      ),
    );
  }
}
