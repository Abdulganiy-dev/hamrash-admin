

import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/viewModel/home_view_model.dart';
import 'package:stacked/stacked.dart';



class Home extends StatefulWidget {
  const Home({super.key});
  static String routeName = '/home';

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HomeViewModel>.reactive(
      viewModelBuilder: () => HomeViewModel(),
      onViewModelReady: (viewModel) {
        this.viewModel = viewModel;
        viewModel.init(context);
      },
      builder: (context, model, _) => DefaultScaffold(
          title: viewModel.title,
          busy: viewModel.busy,
          body: ScaffoldColumn(
            children: [],
          )),
    );
  }
}
