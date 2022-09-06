import 'package:flutter/material.dart';

/// Convert the smalliconbutton to a stateless widget
class SmallIconButton extends StatelessWidget {
  final IconData icon;
  final void Function() onPressed;
  final Color? color;
  final Color? fill;
  final Color? splash;

  const SmallIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.fill,
    this.splash,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: RawMaterialButton(
        elevation: 0,
        fillColor: fill ?? Theme.of(context).colorScheme.background,
        splashColor: splash ?? Colors.grey,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon
          ),
        ),
        onPressed: onPressed,
        shape: const CircleBorder(),
      ),
    );
  }
}

/// Convert the appbackbutton to a stateless widget
class AppBackButton extends StatelessWidget {
  const AppBackButton({Key? key, required this.icon, required this.onPressed}) : super(key: key);

  final IconData icon;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: RawMaterialButton(
        elevation: 0,
        fillColor: Theme.of(context).colorScheme.surface,
        splashColor: Theme.of(context).colorScheme.onBackground,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            size: 32,
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
}

class BigButton extends StatelessWidget {
  const BigButton({
    Key? key, 
    this.icon, 
    required this.label, 
    required this.onPressed,
    this.fillColor,
    this.splashColor,
    this.boxConstraints = const BoxConstraints(minWidth: 88.0, minHeight: 36.0),
  }) : super(key: key);

  final IconData? icon;
  final String label;
  final void Function() onPressed;
  final Color? fillColor;
  final Color? splashColor;
  final BoxConstraints boxConstraints;

  @override 
  Widget build(BuildContext context) {
    return RawMaterialButton(
      fillColor: fillColor ?? Theme.of(context).colorScheme.primary,
      splashColor: splashColor ?? Theme.of(context).colorScheme.secondary,
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
            ),
            const SizedBox(width: 12),
            Flexible(child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
