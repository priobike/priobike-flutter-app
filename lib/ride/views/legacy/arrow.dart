import 'package:flutter/material.dart';

class NavigationArrow extends StatelessWidget {
  const NavigationArrow({
    required this.sign,
    required this.width,
    Key? key,
  }) : super(key: key);

  final int sign;
  final double width;

  Widget inv(String asset) {
    final filter = <double>[
      //R  G   B  A  Const
      -1,  0,  0, 0, 255, //
      0,  -1,  0, 0, 255, //
      0,   0, -1, 0, 255, //
      0,   0,  0, 1, 0, //
    ];

    return ColorFiltered(
      colorFilter: ColorFilter.matrix(filter),
      child: Image.asset(
        asset,
        width: width,
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (sign) {
      case -7:
        return inv('assets/images/dark_keep_left.png');
      case -3:
        return inv('assets/images/dark_turn_sharp_left.png');
      case -2:
        return inv('assets/images/dark_turn_left.png');
      case -1:
        return inv('assets/images/dark_turn_slight_left.png');
      case 0:
        return inv('assets/images/dark_continue.png');
      case 1:
        return inv('assets/images/dark_turn_slight_right.png');
      case 2:
        return inv('assets/images/dark_turn_right.png');
      case 3:
        return inv('assets/images/dark_turn_sharp_right.png');
      case 7:
        return inv('assets/images/dark_keep_right.png');
      case 4:
        return inv('assets/images/dark_finish.png');
      case 6:
        return inv('assets/images/dark_roundabout.png');
      default:
        return inv('assets/images/dark_continue.png');
    }
  }
}