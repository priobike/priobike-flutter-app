import 'package:flutter/material.dart';

/// Function which calculates the RoutingBar height.
double calculateRoutingBarHeight(MediaQueryData frame, int items, bool withSystemBar, bool minimized) {
  if (minimized && items >= 3) {
    // routingBar items set to 3 * 40 + Padding + SystemBar.
    return 3 * 40 + 20 + (withSystemBar ? frame.viewPadding.top : 0);
  }
  // case 1 item
  if (items == 1) {
    // 2 routingBar items (40 + 40) + Padding + SystemBar.
    return 80 + 20 + (withSystemBar ? frame.viewPadding.top : 0);
  }
  // routingBar items * 40 + Padding + SystemBar.
  return items * 40 + 20 + (withSystemBar ? frame.viewPadding.top : 0);
}