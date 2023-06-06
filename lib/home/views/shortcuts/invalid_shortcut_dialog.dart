import 'package:flutter/material.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/services/shortcuts.dart' as shortcuts;
import 'package:priobike/settings/models/backend.dart';

class InvalidShortCutDialog extends AlertDialog {
  InvalidShortCutDialog({
    Key? key,
    required Shortcut shortcut,
    required shortcuts.Shortcuts shortcuts,
    required Backend backend,
    required BuildContext context,
  }) : super(
          key: key,
          title: const Text('Ungültige Strecke'),
          content: Text(
              'Die ausgewählte Strecke ist ungültig, da sie Wegpunkte enthält, die außerhalb des Stadtgebietes von ${backend.region} liegen.\nPrioBike wird aktuell nur innerhalb von ${backend.region} unterstützt.'),
          actions: [
            TextButton(
              child: const Text('Strecke trotzdem behalten'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Strecke löschen'),
              onPressed: () {
                shortcuts.deleteShortcut(shortcut);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
}
