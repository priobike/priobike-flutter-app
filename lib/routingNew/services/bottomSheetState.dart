import 'package:flutter/material.dart';

class BottomSheetState with ChangeNotifier {
  /// The found discomforts.
  bool showRoutingBar = true;

  /// The minimum bottom height of the bottomSheet.
  double initialHeight = 0.175;

  /// The draggableScrollableController used for DraggableScrollView and ListView in BottomSheet.
  DraggableScrollableController draggableScrollableController = DraggableScrollableController();

  /// The draggableScrollableController used for DraggableScrollView and ListView in BottomSheet.
  ScrollController? listController;

  /// The state of saving route or place.
  bool showSaving = false;

  BottomSheetState();

  /// Function which sets the showRoutingBar.
  void setShowRoutingBar() {
    showRoutingBar = true;
    notifyListeners();
  }

  /// Function which unsets the showRoutingBar.
  void setNotShowRoutingBar() {
    showRoutingBar = false;
    notifyListeners();
  }

  /// Function which animates the scroll controller to a given value.
  void animateController(double value) {
    draggableScrollableController.animateTo(value,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic);
    initialHeight = value;
    notifyListeners();
  }

  /// Resets the initial height. Has to be called, when the bottomSheet will be disposed.
  void resetInitialHeight() {
    initialHeight = 0.175;
  }
}
