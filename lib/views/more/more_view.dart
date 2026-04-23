import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:stacked/stacked.dart';

import 'more_view_model.dart';

class MoreView extends StatefulWidget {
  const MoreView({super.key});
  static String routeName = '/more';

  @override
  State<MoreView> createState() => _MoreViewState();
}

class _MoreViewState extends State<MoreView> {
  late MoreViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<MoreViewModel>.reactive(
      viewModelBuilder: () => MoreViewModel(),
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
