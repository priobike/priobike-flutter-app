import 'package:flutter/material.dart';

/// A small icon button.
class SmallIconButton extends SizedBox {
  SmallIconButton({Key? key, required IconData icon, required void Function() onPressed}) : super(
    key: key,
    width: 48,
    height: 48,
    child: RawMaterialButton(
      elevation: 0,
      fillColor: Colors.white,
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
  BigButton({Key? key, IconData? icon, required String label, required void Function() onPressed}) : super(
    key: key,
    fillColor: Colors.blueAccent,
    splashColor: Colors.lightBlue,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(width: 8),
          if (icon != null) Icon(
            icon,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            maxLines: 1,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.normal),
          ),
          const SizedBox(width: 8),
        ],
      ),
    ),
    onPressed: onPressed,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(24)),
    ),
  );
}
