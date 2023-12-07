import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/feedback/views/stars.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

/// Shows a dialog that hints that route/shortcut is invalid.
void showInvalidShortcutSheet(context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withOpacity(0.4),
    pageBuilder: (BuildContext dialogContext, Animation<double> animation, Animation<double> secondaryAnimation) {
      final backend = getIt<Settings>().backend;
      return DialogLayout(
        title: 'Ungültige Strecke',
        text:
            "Die ausgewählte Strecke ist ungültig, da sie Wegpunkte enthält, die außerhalb des Stadtgebietes von ${backend.region} liegen.\nPrioBike wird aktuell nur innerhalb von ${backend.region} unterstützt.",
        icon: Icons.warning_rounded,
        iconColor: CI.radkulturYellow,
        actions: [
          BigButtonPrimary(
            label: 'Schließen',
            onPressed: () => Navigator.of(context).pop(),
            boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
          ),
        ],
      );
    },
  );
}

/// Show a sheet to save a shortcut. If the shortcut is null the current route (at the routing service will be saved).
void showSaveShortcutSheet(context, {Shortcut? shortcut}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor:
        Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.6) : Colors.black.withOpacity(0.8),
    pageBuilder: (BuildContext dialogContext, Animation<double> animation, Animation<double> secondaryAnimation) {
      final nameController = TextEditingController();
      return DialogLayout(
        title: 'Route speichern',
        text: "Bitte gib einen Namen für die Route ein.",
        iconColor: Theme.of(context).colorScheme.primary,
        actions: [
          TextField(
            autofocus: false,
            controller: nameController,
            maxLength: 20,
            decoration: InputDecoration(
              hintText: "Heimweg, Zur Arbeit, ...",
              fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
              filled: true,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                borderSide: BorderSide.none,
              ),
              suffixIcon: SmallIconButtonTertiary(
                icon: Icons.close,
                onPressed: () {
                  nameController.text = "";
                },
                color: Theme.of(context).colorScheme.onBackground,
                fill: Colors.transparent,
                // splash: Colors.transparent,
                withBorder: false,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              counterStyle: TextStyle(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
              ),
            ),
          ),
          BigButtonPrimary(
            label: "Speichern",
            onPressed: () async {
              final name = nameController.text;
              if (name.trim().isEmpty) {
                ToastMessage.showError("Name darf nicht leer sein.");
                return;
              }

              if (shortcut == null) {
                await getIt<Shortcuts>().saveNewShortcutRoute(name);
                ToastMessage.showSuccess("Route gespeichert!");
              } else {
                var oldShortcut = shortcut;
                oldShortcut.name = name;
                await getIt<Shortcuts>().saveNewShortcutObject(oldShortcut);
              }
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
          ),
          BigButtonTertiary(
            label: "Abbrechen",
            onPressed: () async {
              Navigator.pop(context);
            },
            boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
          ),
        ],
      );
    },
  );
}

/// Show a sheet to save a shortcut. If the shortcut is null the current route (at the routing service will be saved).
void showFinishDriveDialog(context, Function submit) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Theme.of(context).colorScheme.secondary.withOpacity(0.6),
    pageBuilder: (BuildContext dialogContext, Animation<double> animation, Animation<double> secondaryAnimation) {
      return DialogLayout(
        title: 'Dein Feedback zur App',
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: StarRatingView(text: "Dein Feedback zur App", displayQuestion: false),
          ),
          BigButtonPrimary(
            label: "Danke!",
            onPressed: () {
              Navigator.pop(context);
              submit();
            },
            boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
          )
        ],
      );
    },
  );
}

/// Our custom dialog layout.
class DialogLayout extends StatefulWidget {
  /// The title of the dialog.
  final String title;

  /// The text content of the dialog.
  final String? text;

  /// The icon of the dialog.
  final IconData? icon;

  /// The color of the icon.
  final Color? iconColor;

  /// The action widgets of the dialog (such as buttons and text input fields).
  final List<Widget>? actions;

  const DialogLayout({
    super.key,
    required this.title,
    this.text,
    required this.actions,
    this.icon,
    this.iconColor,
  });

  @override
  State<StatefulWidget> createState() => DialogLayoutState();
}

/// The state of our custom dialog layout.
class DialogLayoutState extends State<DialogLayout> with WidgetsBindingObserver {
  /// The bottom padding for the dialog (mainly used to push the dialog up when the keyboard is shown).
  double paddingBottom = 0.0;

  /// The intermediate bottom view insets. Not every small bottom view inset change should trigger a rebuild,
  /// because this would cause a lot of rebuilds. Instead, we use this variable to store the intermediate value
  /// and only trigger a rebuild after the value did not change for more than a certain amount of time.
  double intermediateBottomViewInsets = 0.0;

  /// The timer we use to reduce the amount of rebuilds.
  Timer? paddingDelay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    paddingDelay?.cancel();
    super.dispose();
  }

  /// Update the bottom padding of the dialog.
  void updatePadding(double newBottomInsets) {
    if (mounted) {
      setState(() {
        paddingBottom = newBottomInsets / 2;
      });
    }
    paddingDelay = null;
  }

  /// Delay the padding update to reduce the amount of rebuilds.
  Future<void> delayPaddingUpdate(double newBottomInsets) async {
    if (newBottomInsets != intermediateBottomViewInsets) {
      intermediateBottomViewInsets = newBottomInsets / 2;
      if (paddingDelay != null) {
        paddingDelay!.cancel();
      }

      // Only update the padding of the dialog if the bottom view insets did not change for more than 10ms.
      paddingDelay = Timer(const Duration(milliseconds: 10), () => updatePadding(newBottomInsets));
    }
  }

  @override
  void didChangeMetrics() {
    final newPadding = MediaQuery.of(context).viewInsets;
    delayPaddingUpdate(newPadding.bottom);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> actions = List.empty(growable: true);

    if (widget.actions != null) {
      final length = widget.actions!.length;
      for (var i = 0; i < length; i++) {
        actions.add(widget.actions![i]);
        // Add a small vertical space between the actions.
        if (i < length - 1) actions.add(const SmallVSpace());
      }
    }

    // Initial state of the bottom padding.
    paddingBottom = MediaQuery.of(context).viewInsets.bottom;

    final orientation = MediaQuery.of(context).orientation;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: paddingBottom),
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
      child: Center(
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: orientation == Orientation.portrait
                    ? MediaQuery.of(context).size.width * 0.8
                    : MediaQuery.of(context).size.width * 0.6,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  color: Theme.of(context).colorScheme.background.withOpacity(0.6),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null)
                        Icon(
                          widget.icon!,
                          color: widget.iconColor ?? Theme.of(context).colorScheme.primary,
                          size: 36,
                        ),
                      if (widget.icon != null) const SmallVSpace(),
                      BoldSubHeader(
                        context: context,
                        text: widget.title,
                        textAlign: TextAlign.center,
                      ),
                      if (widget.text != null) ...[
                        const SmallVSpace(),
                        Content(
                          context: context,
                          text: widget.text!,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (widget.actions != null) ...[
                        const SmallVSpace(),
                        ...actions,
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
