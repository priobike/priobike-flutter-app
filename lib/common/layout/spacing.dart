import 'package:flutter/material.dart';

/// A regular vertical padding.
class VPad extends Padding {
  const VPad({super.key, required Widget super.child}) : super(padding: const EdgeInsets.symmetric(vertical: 24));
}

/// A regular horizontal padding.
class HPad extends Padding {
  const HPad({super.key, required Widget super.child}) : super(padding: const EdgeInsets.symmetric(horizontal: 24));
}

/// A regular padding.
class Pad extends Padding {
  const Pad({super.key, required Widget super.child}) : super(padding: const EdgeInsets.all(32));
}

/// A regular vertical space.
class VSpace extends SizedBox {
  const VSpace({super.key}) : super(height: 24);
}

/// A small vertical space.
class SmallVSpace extends SizedBox {
  const SmallVSpace({super.key}) : super(height: 8);
}

/// A regular horizontal space.
class HSpace extends SizedBox {
  const HSpace({super.key}) : super(width: 24);
}

/// A small horizontal space.
class SmallHSpace extends SizedBox {
  const SmallHSpace({super.key}) : super(width: 8);
}
