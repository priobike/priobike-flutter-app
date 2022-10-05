import 'package:flutter/material.dart';


class BottomSheetState with ChangeNotifier {
  /// The found discomforts.
  bool showRoutingBar = true;


  BottomSheetState();

  void setShowRoutingBar() {
    showRoutingBar = true;
    notifyListeners();
  }

  void setNotShowRoutingBar() {
    showRoutingBar = false;
    notifyListeners();
  }
}