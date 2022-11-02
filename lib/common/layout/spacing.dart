import 'package:flutter/material.dart';

/// A regular vertical padding.
class VPad extends Padding {
  const VPad({Key? key, required Widget child})
      : super(
            key: key,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: child);
}

/// A regular horizontal padding.
class HPad extends Padding {
  const HPad({Key? key, required Widget child})
      : super(
            key: key,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: child);
}

/// A regular padding.
class Pad extends Padding {
  const Pad({Key? key, required Widget child})
      : super(key: key, padding: const EdgeInsets.all(32), child: child);
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
