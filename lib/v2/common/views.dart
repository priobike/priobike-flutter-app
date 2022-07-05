

import 'package:flutter/material.dart';
import 'package:priobike/v2/common/colors.dart';

/// A fade wrapper to fade out views at the bottom and top of the screen.
class Fade extends ShaderMask {
  Fade({Key? key, required Widget child}) : super(
    key: key, 
    shaderCallback: (Rect rect) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.purple, Colors.transparent, Colors.transparent, Colors.purple],
        stops: [0.0, 0.1, 0.7, 1.0],
      ).createShader(rect);
    },
    blendMode: BlendMode.dstOut, 
    child: child
  );
}

class Tile extends RawMaterialButton {
  Tile({
    Key? key, 
    required Widget content, 
    void Function()? onPressed,
    Color fill = AppColors.lightGrey,
    Color splash = Colors.white,
  }) : super(
    key: key,
    elevation: 0,
    fillColor: fill,
    splashColor: splash,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: content,
    ),
    onPressed: onPressed,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(24)),
    ),
  );
}

class ColorTile extends Tile {
  ColorTile({
    Key? key, 
    required Widget content, 
    void Function()? onPressed,
    Color fill = Colors.blueAccent,
    Color splash = Colors.lightBlue,
  }) : super(
    key: key,
    content: content,
    onPressed: onPressed,
    fill: Colors.blueAccent,
    splash: Colors.lightBlue,
  );
}

/// A small icon button.
class SmallIconButton extends SizedBox {
  SmallIconButton({Key? key, required IconData icon, required void Function() onPressed}) : super(
    key: key,
    width: 48,
    height: 48,
    child: RawMaterialButton(
      elevation: 0,
      fillColor: AppColors.lightGrey,
      splashColor: Colors.white,
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

/// A header text.
class Header extends Text {
  Header({Key? key, required String text, Color color = Colors.black}) : super(
    text, 
    key: key, 
    style: TextStyle(fontSize: 38, fontWeight: FontWeight.w600, color: color),
  );
}

/// A sub header text.
class SubHeader extends Text {
  SubHeader({Key? key, required String text, Color color = Colors.black}) : super(
    text, 
    key: key, 
    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300, color: color)
  );
}

/// A content text.
class Content extends Text {
  Content({Key? key, required String text, Color color = Colors.black}) : super(
    text, 
    key: key, 
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300, color: color)
  );
}

/// A content text.
class Small extends Text {
  Small({Key? key, required String text, Color color = Colors.black}) : super(
    text, 
    key: key, 
    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300, color: color)
  );
}

/// A regular vertical padding.
class VPad extends Padding {
  const VPad({Key? key, required Widget child}) : super(
    key: key, 
    padding: const EdgeInsets.symmetric(vertical: 32), 
    child: child
  );
}

/// A regular horizontal padding.
class HPad extends Padding {
  const HPad({Key? key, required Widget child}) : super(
    key: key, 
    padding: const EdgeInsets.symmetric(horizontal: 32), 
    child: child
  );
}

/// A regular padding.
class Pad extends Padding {
  const Pad({Key? key, required Widget child}) : super(
    key: key, 
    padding: const EdgeInsets.all(32), 
    child: child
  );
}

/// A regular vertical space.
class VSpace extends SizedBox {
  const VSpace({Key? key}) : super(key: key, height: 24);
}

/// A small vertical space.
class SmallVSpace extends SizedBox {
  const SmallVSpace({Key? key}) : super(key: key, height: 8);
}

/// A regular horizontal space.
class HSpace extends SizedBox {
  const HSpace({Key? key}) : super(key: key, width: 24);
}

/// A small horizontal space.
class SmallHSpace extends SizedBox {
  const SmallHSpace({Key? key}) : super(key: key, width: 8);
}

/// A list item with icon.
class IconItem extends Row {
  IconItem({Key? key, required IconData icon, required String text}) : super(
    key: key,
    children: [
      SizedBox(
        width: 64,
        height: 64,
        child: Icon(
          icon,
          color: Colors.blueAccent,
          size: 64,
          semanticLabel: text,
        )
      ),
      const SmallHSpace(),
      Expanded(child: Content(text: text)),
    ]
  );
}