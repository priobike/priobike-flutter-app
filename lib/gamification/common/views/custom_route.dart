import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/utils.dart';

class CustosmRoute extends PageRouteBuilder {
  CustosmRoute({required Widget view})
      : super(
          transitionDuration: TinyDuration(),
          reverseTransitionDuration: TinyDuration(),
          pageBuilder: (context, animation, secondaryAnimation) => view,
        );
}
