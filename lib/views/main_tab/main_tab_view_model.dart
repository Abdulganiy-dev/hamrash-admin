import 'package:flutter/material.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';

class MainTabViewModel extends BaseViewModel {
  late BuildContext context;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void init(BuildContext context) {
    this.context = context;
  }

  void setIndex(int index) {
    if (index == _currentIndex) return;
    _currentIndex = index;
    notifyListeners();
  }
}
