
import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:stacked/stacked.dart';

import 'template_view_model.dart';

class Template extends StatefulWidget {
  const Template({super.key});
  static String routeName = '/template';

  @override
  State<Template> createState() => _TemplateState();
}

class _TemplateState extends State<Template> {
  late TemplateViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<TemplateViewModel>.reactive(
      viewModelBuilder: () => TemplateViewModel(),
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
