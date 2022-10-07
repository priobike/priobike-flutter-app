import 'package:flutter/material.dart';

class BottomSheetState with ChangeNotifier {
  /// The found discomforts.
  bool showRoutingBar = true;

  /// The draggableScrollableController used for DraggableScrollView and ListView in BottomSheet
  DraggableScrollableController draggableScrollableController =
      DraggableScrollableController();

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
