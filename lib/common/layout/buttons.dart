import 'package:flutter/material.dart';
import 'package:priobike/common/colors.dart';

/// A small icon button.
class SmallIconButton extends SizedBox {
  SmallIconButton({
    Key? key, 
    required IconData icon, 
    required void Function() onPressed,
    Color color = Colors.black,
    Color fill = AppColors.lightGrey,
    Color splash = Colors.grey,
  }) : super(
    key: key,
    width: 48,
    height: 48,
    child: RawMaterialButton(
      elevation: 0,
      fillColor: fill,
      splashColor: splash,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          color: color,
        ),
      ),
      onPressed: onPressed,
      shape: const CircleBorder(),
    ),
  );
}

class AppBackButton extends SizedBox {
  AppBackButton({Key? key, required IconData icon, required void Function() onPressed}) : super(
    key: key,
    width: 64,
    height: 64,
    child: RawMaterialButton(
      elevation: 0,
      fillColor: Colors.white,
      splashColor: Colors.grey,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          size: 32,
          color: Colors.black,
        ),
      ),
      onPressed: onPressed,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24), 
          bottomRight: Radius.circular(24)
        ),
      ),
    ),
  );
}

/// A big button.
class BigButton extends RawMaterialButton {
  BigButton({
    Key? key, 
    IconData? icon, 
    required String label, 
    required void Function() onPressed,
    Color fillColor = Colors.blueAccent,
    Color splashColor = Colors.white,
    BoxConstraints boxConstraints = const BoxConstraints(minWidth: 88.0, minHeight: 36.0),
  }) : super(
    key: key,
    fillColor: fillColor,
    splashColor: splashColor,
    constraints: boxConstraints,
    elevation: 0,
    focusElevation: 0,
    hoverElevation: 0,
    highlightElevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(width: 32),
          if (icon != null) Icon(
            icon,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Flexible(child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          )),
          const SizedBox(width: 32),
        ],
      ),
    ),
    onPressed: onPressed,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  );
}
