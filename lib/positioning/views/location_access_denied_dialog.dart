import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/positioning/sources/interface.dart';

/// Show a dialog if the location provider was denied.
void showLocationAccessDeniedDialog(BuildContext context, PositionSource? positionSource) {
  Widget okButton = TextButton(
    child: const Text("Einstellungen öffnen"),
    onPressed: () => positionSource?.openLocationSettings(),
  );
  AlertDialog alert = AlertDialog(
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(24)),
    ),
    backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.95),
    title: SubHeader(
      text: "Zugriff auf Standort verweigert.",
      context: context,
    ),
    content: Content(
      text: "Bitte erlauben Sie den Zugriff auf Ihren Standort in den Einstellungen.",
      context: context,
    ),
    actions: [okButton],
  );
  showDialog(context: context, builder: (BuildContext context) => alert);
}
