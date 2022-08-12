import 'package:flutter/material.dart';
import 'package:priobike/common/colors.dart';

class Tile extends RawMaterialButton {
  Tile({
    Key? key, 
    required Widget content, 
    void Function()? onPressed,
    Color fill = AppColors.lightGrey,
    Color splash = Colors.grey,
    EdgeInsets padding = const EdgeInsets.all(16),
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(24)),
  }) : super(
    key: key,
    elevation: 0,
    hoverElevation: 0,
    focusElevation: 0,
    highlightElevation: 0,
    fillColor: fill,
    splashColor: splash,
    child: Padding(
      padding: padding,
      child: content,
    ),
    onPressed: onPressed,
    shape: RoundedRectangleBorder(borderRadius: borderRadius),
  );
}