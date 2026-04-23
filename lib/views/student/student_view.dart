import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:stacked/stacked.dart';

import 'student_view_model.dart';

class StudentView extends StatefulWidget {
  const StudentView({super.key});
  static String routeName = '/student';

  @override
  State<StudentView> createState() => _StudentViewState();
}

class _StudentViewState extends State<StudentView> {
  late StudentViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<StudentViewModel>.reactive(
      viewModelBuilder: () => StudentViewModel(),
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
