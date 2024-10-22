import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/positioning/sources/interface.dart';

/// Show a dialog if the location provider was denied.
void showLocationAccessDeniedDialog(BuildContext context, PositionSource? positionSource) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withOpacity(0.4),
    transitionBuilder: (context, animation, secondaryAnimation, child) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4 * animation.value, sigmaY: 4 * animation.value),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    ),
    pageBuilder: (BuildContext dialogContext, Animation<double> animation, Animation<double> secondaryAnimation) {
      return DialogLayout(
        title: "Zugriff auf Standort verweigert.",
        text: "Bitte erlaube den Zugriff auf Deinen Standort in den Einstellungen.",
        icon: Icons.location_off_rounded,
        iconColor: Theme.of(context).colorScheme.primary,
        actions: [
          BigButtonPrimary(
            label: 'Einstellungen öffnen',
            onPressed: () => positionSource?.openLocationSettings(),
            boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
          ),
        ],
      );
    },
  );
}
