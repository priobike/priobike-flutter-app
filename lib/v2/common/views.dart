

import 'package:flutter/material.dart';

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
  const Header({Key? key, required String text}) : super(
    text, 
    key: key, 
    style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w600)
  );
}

/// A colorized header text.
class ColorHeader extends Text {
  const ColorHeader({Key? key, required String text}) : super(
    text, 
    key: key, 
    style: const TextStyle(fontSize: 38, color: Colors.blueAccent, fontWeight: FontWeight.bold)
  );
}

/// A sub header text.
class SubHeader extends Text {
  const SubHeader({Key? key, required String text}) : super(
    text, 
    key: key, 
    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w300)
  );
}

/// A content text.
class Content extends Text {
  const Content({Key? key, required String text}) : super(
    text, 
    key: key, 
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w300)
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
  const VSpace({Key? key}) : super(key: key, height: 32);
}

/// A small vertical space.
class SmallVSpace extends SizedBox {
  const SmallVSpace({Key? key}) : super(key: key, height: 8);
}

/// A regular horizontal space.
class HSpace extends SizedBox {
  const HSpace({Key? key}) : super(key: key, width: 32);
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