import 'package:flutter/material.dart' hide Shortcuts;
import 'package:get_it/get_it.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/logging/toast.dart';

/// Show a sheet to save the current route as a shortcut.
void showSaveShortcutSheet(BuildContext context, ShortcutRoute shortcut) {
  final shortcuts = GetIt.instance.get<Shortcuts>();
  showDialog(
    context: context,
    builder: (_) {
      final nameController = TextEditingController();
      return AlertDialog(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
        insetPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 40.0),
        title: BoldContent(
          text: 'Bitte gib einen Namen an, unter dem die Strecke gespeichert werden soll.',
          context: context,
        ),
        content: SizedBox(
          height: 78,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                maxLength: 20,
                decoration: const InputDecoration(hintText: 'Heimweg, Zur Arbeit, ...'),
              ),
            ],
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final name = nameController.text;
              if (name.trim().isEmpty) {
                ToastMessage.showError("Name darf nicht leer sein.");
                return;
              }
              shortcut.name = name;
              await shortcuts.saveNewShortcutObject(shortcut);
              ToastMessage.showSuccess("Route gespeichert!");
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: BoldContent(
              text: 'Speichern',
              color: Theme.of(context).colorScheme.primary,
              context: context,
            ),
          ),
        ],
      );
    },
  );
}
