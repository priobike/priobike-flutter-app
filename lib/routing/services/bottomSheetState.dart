import 'package:flutter/material.dart';

class BottomSheetState with ChangeNotifier {
  /// The found discomforts.
  bool showRoutingBar = true;

  /// The draggableScrollableController used for DraggableScrollView and ListView in BottomSheet.
  DraggableScrollableController draggableScrollableController =
      DraggableScrollableController();

  /// The draggableScrollableController used for DraggableScrollView and ListView in BottomSheet.
  ScrollController? listController;

  BottomSheetState();

  void setShowRoutingBar() {
    showRoutingBar = true;
    notifyListeners();
  }

  void setNotShowRoutingBar() {
    showRoutingBar = false;
    notifyListeners();
  }

  void animateController(double value) {
    draggableScrollableController.animateTo(
        value,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic);
    notifyListeners();
  }
}
