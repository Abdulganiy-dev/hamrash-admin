

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/default_scaffold.dart';
import 'package:hamrash_admin/resources/extensions.dart';
import 'package:hamrash_admin/resources/spacing_constants.dart';
import 'package:hamrash_admin/viewModel/home_view_model.dart';
import 'package:hamrash_admin/widgets/app_text.dart';
import 'package:hamrash_admin/widgets/cached_network_image_widget.dart';
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
        title: null,
        busy: viewModel.busy,
        appBarType: DefaultScaffoldAppBarType.none,
        body: Builder(
          builder: (context) => SingleChildScrollView(
            child: ScaffoldColumn(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: ScaffoldInsets.of(context).bodyTopInset + 50),
                CachedNetworkImageWidget(imageUrl: viewModel.profileImageUrl ?? '', width: 100, height: 100,borderRadius: 100,).padding(bottom: AppSpacing.md),
                AppText("${getGreeting()}\n${viewModel.fullName}",colorType: AppTextColor.textInverted,fontWeight: FontWeight.w800,fontSize: 24,).padding(bottom: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }


  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 18) return 'Good Afternoon';
    return 'Good Evening';
  }
}
