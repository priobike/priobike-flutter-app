import 'package:flutter/material.dart';

/// A small icon button.
class SmallIconButton extends StatelessWidget {
  /// The icon to be displayed.
  final IconData icon;

  /// The callback that is executed when the button is pressed.
  final void Function() onPressed;

  /// The optional icon color of the button.
  final Color? color;

  /// The optional fill color of the button.
  final Color? fill;

  /// The optional splash color of the button.
  final Color? splash;

  const SmallIconButton({
    required this.icon,
    required this.onPressed,
    this.color,
    this.fill,
    this.splash,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.04),
          width: 1,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(24)),
      ),
      child: RawMaterialButton(
        elevation: 0, // Hide ugly material shadows.
        fillColor: fill ?? Theme.of(context).colorScheme.background,
        splashColor: splash ?? Colors.grey,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(
            icon,
            color: color ?? Theme.of(context).colorScheme.onBackground,
          ),
        ),
        onPressed: onPressed,
        shape: const CircleBorder(),
      ),
    );
  }
}

/// A custom stylized button that is used to navigate back.
class AppBackButton extends StatelessWidget {
  /// The icon of the button.
  final IconData icon;

  /// The callback that is executed when the button is pressed.
  final void Function() onPressed;

  const AppBackButton({
    this.icon = Icons.chevron_left,
    required this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: RawMaterialButton(
        elevation: 0, // Hide ugly material shadows.
        fillColor: Theme.of(context).colorScheme.background,
        splashColor: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 8, top: 12, bottom: 12),
          child: Icon(
            icon,
            size: 32,
          ),
        ),
        onPressed: onPressed,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(24), bottomRight: Radius.circular(24)),
        ),
      ),
    );
  }
}

/// A custom stylized button to display important actions.
class BigButton extends StatelessWidget {
  /// The icon of the button.
  final IconData? icon;

  /// The label of the button.
  final String label;

  /// The callback that is executed when the button was pressed.
  final void Function() onPressed;

  /// The optional fill color of the button.
  final Color? fillColor;

  /// The optional splash color of the button.
  final Color? splashColor;

  /// The optional icon color of the button.
  final Color? iconColor;

  /// The constraints to define a specific size for the button.
  final BoxConstraints boxConstraints;

  const BigButton({
    Key? key,
    this.icon,
    required this.label,
    required this.onPressed,
    this.fillColor,
    this.splashColor,
    this.iconColor,
    this.boxConstraints = const BoxConstraints(minWidth: 88.0, minHeight: 36.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      fillColor: fillColor ?? Theme.of(context).colorScheme.primary,
      splashColor: splashColor ?? Theme.of(context).colorScheme.secondary,
      constraints: boxConstraints,
      // Hide ugly material shadows.
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
            if (icon != null)
              Icon(
                icon,
                color: iconColor,
              ),
            const SizedBox(width: 12),
            Flexible(
                child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
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
}
