import 'package:flutter/material.dart';

class NavigationArrow extends StatelessWidget {
  const NavigationArrow({
    required this.sign,
    required this.width,
    Key? key,
  }) : super(key: key);

  final int sign;
  final double width;

  @override
  Widget build(BuildContext context) {
    switch (sign) {
      case -7:
        return Image.asset(
          'assets/images/dark_keep_left.png',
          width: width,
        );
      case -3:
        return Image.asset(
          'assets/images/dark_turn_sharp_left.png',
          width: width,
        );
      case -2:
        return Image.asset(
          'assets/images/dark_turn_left.png',
          width: width,
        );
      case -1:
        return Image.asset(
          'assets/images/dark_turn_slight_left.png',
          width: width,
        );
      case 0:
        return Image.asset(
          'assets/images/dark_continue.png',
          width: width,
        );
      case 1:
        return Image.asset(
          'assets/images/dark_turn_slight_right.png',
          width: width,
        );
      case 2:
        return Image.asset(
          'assets/images/dark_turn_right.png',
          width: width,
        );
      case 3:
        return Image.asset(
          'assets/images/dark_turn_sharp_right.png',
          width: width,
        );
      case 7:
        return Image.asset(
          'assets/images/dark_keep_right.png',
          width: width,
        );
      case 4:
        return Image.asset(
          'assets/images/dark_finish.png',
          width: width,
        );
      case 6:
        return Image.asset(
          'assets/images/dark_roundabout.png',
          width: width,
        );
      default:
        return Image.asset(
          'assets/images/dark_continue.png',
          width: width,
        );
    }
  }
}