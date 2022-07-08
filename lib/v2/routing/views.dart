

import 'package:flutter/material.dart';
import 'package:priobike/v2/common/debug.dart';
import 'package:priobike/v2/common/views/map.dart';

/// Debug these views.
void main() => debug(const RoutingView());

class RoutingView extends StatelessWidget {
  const RoutingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      AppMap(),
    ]);
  }
}
