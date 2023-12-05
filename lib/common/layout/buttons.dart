import 'package:flutter/material.dart';

/// A small icon button (primary).
class SmallIconButtonPrimary extends StatelessWidget {
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

  /// The optional splash color of the button.
  final bool withBorder;

  const SmallIconButtonPrimary({
    required this.icon,
    required this.onPressed,
    this.color,
    this.fill,
    this.splash,
    this.withBorder = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: RawMaterialButton(
        elevation: 0,
        // Hide ugly material shadows.
        fillColor: fill ?? Theme.of(context).colorScheme.primary,
        splashColor: splash ?? Theme.of(context).colorScheme.onPrimary,
        onPressed: onPressed,
        shape: CircleBorder(
            side: BorderSide(
          width: 1,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.04),
        )),
        child: Center(
          child: Icon(
            icon,
            color: color ?? Colors.white,
          ),
        ),
      ),
    );
  }
}

/// A small icon button (secondary).
class SmallIconButtonSecondary extends StatelessWidget {
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

  /// The optional border colors of the button.
  final Color? borderColor;

  /// The optional splash color of the button.
  final bool withBorder;

  const SmallIconButtonSecondary({
    required this.icon,
    required this.onPressed,
    this.color,
    this.fill,
    this.splash,
    this.borderColor,
    this.withBorder = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: RawMaterialButton(
        elevation: 0,
        // Hide ugly material shadows.
        fillColor: fill ?? Theme.of(context).colorScheme.surfaceVariant,
        splashColor: splash ?? Theme.of(context).colorScheme.onSecondary,
        onPressed: onPressed,
        shape: CircleBorder(
            side: BorderSide(
          width: 1,
          color: borderColor != null ? borderColor! : Theme.of(context).colorScheme.primary,
        )),
        child: Center(
          child: Icon(
            icon,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// A small icon button (tertiary).
class SmallIconButtonTertiary extends StatelessWidget {
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

  /// The optional border colors of the button.
  final Color? borderColor;

  /// The optional splash color of the button.
  final bool withBorder;

  const SmallIconButtonTertiary({
    required this.icon,
    required this.onPressed,
    this.color,
    this.fill,
    this.splash,
    this.borderColor,
    this.withBorder = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: RawMaterialButton(
        elevation: 0,
        // Hide ugly material shadows.
        fillColor: fill ?? Theme.of(context).colorScheme.surfaceVariant,
        splashColor: splash ?? Theme.of(context).colorScheme.onTertiary,
        onPressed: onPressed,
        shape: CircleBorder(
            side: BorderSide(
                width: 1, color: borderColor != null ? borderColor! : Theme.of(context).colorScheme.onTertiary)),
        child: Center(
          child: Icon(
            icon,
            color: color ?? Theme.of(context).colorScheme.tertiary,
          ),
        ),
      ),
    );
  }
}

/// A custom stylized button that is used to navigate back.
class AppBackButton extends StatelessWidget {
  /// The icon of the button.
  final IconData icon;

  /// The callback that is executed when the button is pressed.
  final void Function()? onPressed;
  final double? elevation;

  const AppBackButton({
    this.icon = Icons.chevron_left,
    this.onPressed,
    this.elevation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: RawMaterialButton(
        elevation: elevation ?? 0,
        fillColor: Theme.of(context).colorScheme.surfaceVariant,
        splashColor: Theme.of(context).colorScheme.surfaceTint,
        onPressed: onPressed,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topRight: Radius.circular(24), bottomRight: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8, top: 12, bottom: 12),
          child: Icon(
            icon,
            size: 32,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// A custom stylized button to display important actions (primary).
class BigButtonPrimary extends StatelessWidget {
  /// The icon of the button.
  final IconData? icon;

  /// The label of the button.
  final String label;

  /// The callback that is executed when the button was pressed.
  final void Function()? onPressed;

  /// The optional fill color of the button.
  final Color? fillColor;

  /// The optional splash color of the button.
  final Color? splashColor;

  /// The optional icon color of the button.
  final Color? iconColor;

  /// The optional text color of the button.
  final Color? textColor;

  /// The constraints to define a specific size for the button.
  final BoxConstraints boxConstraints;

  /// The optional elevation of the button.
  final double elevation;

  const BigButtonPrimary({
    super.key,
    this.icon,
    required this.label,
    this.onPressed,
    this.fillColor,
    this.splashColor,
    this.iconColor,
    this.textColor,
    this.boxConstraints = const BoxConstraints(minWidth: 88.0, minHeight: 36.0),
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      fillColor: fillColor ?? Theme.of(context).colorScheme.surface,
      splashColor: splashColor ?? Theme.of(context).colorScheme.surfaceTint,
      constraints: boxConstraints,
      // Hide ugly material shadows.
      elevation: elevation,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      onPressed: onPressed,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(width: 32),
            if (icon != null)
              Row(
                children: [
                  Icon(
                    icon,
                    color: iconColor ?? Colors.white,
                    size: 22,
                  ),
                  const SizedBox(
                    width: 12,
                  )
                ],
              ),
            Container(
              height: 24,
              alignment: Alignment.center,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 32),
          ],
        ),
      ),
    );
  }
}

/// A custom stylized button to display important actions (secondary).
class BigButtonSecondary extends StatelessWidget {
  /// The icon of the button.
  final IconData? icon;

  /// The label of the button.
  final String label;

  /// The callback that is executed when the button was pressed.
  final void Function()? onPressed;

  /// The optional fill color of the button.
  final Color? fillColor;

  /// The optional splash color of the button.
  final Color? splashColor;

  /// The optional icon color of the button.
  final Color? iconColor;

  /// The optional text color of the button.
  final Color? textColor;

  /// The constraints to define a specific size for the button.
  final BoxConstraints boxConstraints;

  /// The optional elevation of the button.
  final double elevation;

  const BigButtonSecondary({
    super.key,
    this.icon,
    required this.label,
    this.onPressed,
    this.fillColor,
    this.splashColor,
    this.iconColor,
    this.textColor,
    this.boxConstraints = const BoxConstraints(minWidth: 88.0, minHeight: 36.0),
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      fillColor: fillColor ?? Theme.of(context).colorScheme.surfaceVariant,
      splashColor: splashColor ?? Theme.of(context).colorScheme.onSecondary,
      constraints: boxConstraints,
      // Hide ugly material shadows.
      elevation: elevation,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      onPressed: onPressed,
      shape: RoundedRectangleBorder(
        side: BorderSide(width: 1, color: Theme.of(context).colorScheme.primary),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(width: 32),
            if (icon != null)
              Row(
                children: [
                  Icon(
                    icon,
                    color: iconColor ?? Theme.of(context).colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(
                    width: 12,
                  )
                ],
              ),
            Container(
              height: 24,
              alignment: Alignment.center,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor ?? Theme.of(context).colorScheme.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 32),
          ],
        ),
      ),
    );
  }
}

/// A custom stylized button to display important actions (tertiary).
class BigButtonTertiary extends StatelessWidget {
  /// The icon of the button.
  final IconData? icon;

  /// The label of the button.
  final String label;

  /// The callback that is executed when the button was pressed.
  final void Function()? onPressed;

  /// The optional fill color of the button.
  final Color? fillColor;

  /// The optional splash color of the button.
  final Color? splashColor;

  /// The optional icon color of the button.
  final Color? iconColor;

  /// The optional text color of the button.
  final Color? textColor;

  /// The constraints to define a specific size for the button.
  final BoxConstraints boxConstraints;

  /// The optional elevation of the button.
  final double elevation;

  const BigButtonTertiary({
    super.key,
    this.icon,
    required this.label,
    this.onPressed,
    this.fillColor,
    this.splashColor,
    this.iconColor,
    this.textColor,
    this.boxConstraints = const BoxConstraints(minWidth: 88.0, minHeight: 36.0),
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      fillColor: fillColor ?? Theme.of(context).colorScheme.surfaceVariant,
      splashColor: splashColor ?? Theme.of(context).colorScheme.onTertiary,
      constraints: boxConstraints,
      // Hide ugly material shadows.
      elevation: elevation,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      onPressed: onPressed,
      shape: RoundedRectangleBorder(
        side: BorderSide(width: 1, color: Theme.of(context).colorScheme.onTertiary),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(width: 32),
            if (icon != null)
              Row(
                children: [
                  Icon(
                    icon,
                    color: iconColor ?? Theme.of(context).colorScheme.tertiary,
                    size: 22,
                  ),
                  const SizedBox(
                    width: 12,
                  )
                ],
              ),
            Container(
              height: 24,
              alignment: Alignment.center,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor ?? Theme.of(context).colorScheme.tertiary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 32),
          ],
        ),
      ),
    );
  }
}

/// A custom stylized button to display important actions.
class IconTextButtonPrimary extends StatelessWidget {
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

  /// The optional border color of the button.
  final Color? borderColor;

  /// The optional border color of the button.
  final Color? textColor;

  const IconTextButtonPrimary({
    super.key,
    this.icon,
    required this.label,
    required this.onPressed,
    this.fillColor,
    this.splashColor,
    this.iconColor,
    this.boxConstraints = const BoxConstraints(minWidth: 75.0, minHeight: 10.0),
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      fillColor: fillColor ?? Theme.of(context).colorScheme.surface,
      splashColor: splashColor ?? Theme.of(context).colorScheme.surfaceTint,
      constraints: boxConstraints,
      // Hide ugly material shadows.
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onPressed: onPressed,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: borderColor ?? Colors.transparent),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(width: 2),
            if (icon != null)
              Icon(
                icon,
                color: iconColor,
              ),
            SizedBox(width: icon != null ? 2 : 0),
            Flexible(
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textColor ?? Colors.white, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 2),
          ],
        ),
      ),
    );
  }
}

/// A custom stylized button to display important actions.
class IconTextButtonSecondary extends StatelessWidget {
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

  /// The optional border color of the button.
  final Color? borderColor;

  /// The optional border color of the button.
  final Color? textColor;

  const IconTextButtonSecondary({
    super.key,
    this.icon,
    required this.label,
    required this.onPressed,
    this.fillColor,
    this.splashColor,
    this.iconColor,
    this.boxConstraints = const BoxConstraints(minWidth: 75.0, minHeight: 10.0),
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      fillColor: fillColor ?? Theme.of(context).colorScheme.surfaceVariant,
      splashColor: splashColor ?? Theme.of(context).colorScheme.onSecondary,
      constraints: boxConstraints,
      // Hide ugly material shadows.
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onPressed: onPressed,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: borderColor ?? Theme.of(context).colorScheme.primary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(width: 2),
            if (icon != null)
              Icon(
                icon,
                color: iconColor ?? Theme.of(context).colorScheme.primary,
              ),
            SizedBox(width: icon != null ? 2 : 0),
            Flexible(
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textColor ?? Theme.of(context).colorScheme.primary, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 2),
          ],
        ),
      ),
    );
  }
}

/// A custom stylized button to display important actions.
class IconTextButtonTertiary extends StatelessWidget {
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

  /// The optional border color of the button.
  final Color? borderColor;

  /// The optional border color of the button.
  final Color? textColor;

  const IconTextButtonTertiary({
    super.key,
    this.icon,
    required this.label,
    required this.onPressed,
    this.fillColor,
    this.splashColor,
    this.iconColor,
    this.boxConstraints = const BoxConstraints(minWidth: 75.0, minHeight: 10.0),
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      fillColor: fillColor ?? Theme.of(context).colorScheme.surfaceVariant,
      splashColor: splashColor ?? Theme.of(context).colorScheme.onTertiary,
      constraints: boxConstraints,
      // Hide ugly material shadows.
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onPressed: onPressed,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: borderColor ?? Theme.of(context).colorScheme.onTertiary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(width: 2),
            if (icon != null)
              Icon(
                icon,
                color: iconColor ?? Theme.of(context).colorScheme.tertiary,
              ),
            SizedBox(width: icon != null ? 2 : 0),
            Flexible(
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textColor ?? Theme.of(context).colorScheme.tertiary, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 2),
          ],
        ),
      ),
    );
  }
}
