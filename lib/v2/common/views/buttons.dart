
import 'package:flutter/material.dart';
import 'package:priobike/v2/common/colors.dart';

/// A small icon button.
class SmallIconButton extends SizedBox {
  SmallIconButton({Key? key, required IconData icon, required void Function() onPressed}) : super(
    key: key,
    width: 48,
    height: 48,
    child: RawMaterialButton(
      elevation: 0,
      fillColor: AppColors.lightGrey,
      splashColor: Colors.grey,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          color: Colors.black,
        ),
      ),
      onPressed: onPressed,
      shape: const CircleBorder(),
    ),
  );
}

/// A big button.
class BigButton extends RawMaterialButton {
  BigButton({Key? key, required IconData icon, required String label, required void Function() onPressed}) : super(
    key: key,
    fillColor: Colors.blueAccent,
    splashColor: Colors.lightBlue,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(width: 16),
          Icon(
            icon,
            color: Colors.white,
          ),
          const SizedBox(width: 16),
          Text(
            label,
            maxLines: 1,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.normal),
          ),
          const SizedBox(width: 16),
        ],
      ),
    ),
    onPressed: onPressed,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(24)),
    ),
  );
}
