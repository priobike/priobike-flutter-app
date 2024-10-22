import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/feedback/views/stars.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/geosearch.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

/// Shows a dialog that hints that route/shortcut is invalid.
void showInvalidShortcutSheet(context) {
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
      final city = getIt<Settings>().city;
      return DialogLayout(
        title: 'Ungültige Strecke',
        text:
            "Die ausgewählte Strecke ist ungültig, da sie Wegpunkte enthält, die außerhalb des Stadtgebietes von ${city.nameDE} liegen.\nPrioBike wird aktuell nur innerhalb von ${city.nameDE} unterstützt.",
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

/// Show a sheet to save a shortcut.
void showSaveShortcutSheet(context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor:
        Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.4),
    transitionBuilder: (context, animation, secondaryAnimation, child) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4 * animation.value, sigmaY: 4 * animation.value),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    ),
    pageBuilder: (BuildContext dialogContext, Animation<double> animation, Animation<double> secondaryAnimation) {
      final nameController = TextEditingController();
      return DialogLayout(
        title: 'Route speichern',
        text: "Bitte gib einen Namen für die Route ein.",
        actions: [
          TextField(
            autofocus: false,
            controller: nameController,
            maxLength: 20,
            decoration: InputDecoration(
              hintText: "Heimweg, Zur Arbeit, ...",
              fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                color: Theme.of(context).colorScheme.onSurface,
                fill: Colors.transparent,
                // splash: Colors.transparent,
                withBorder: false,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              counterStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          BigButtonPrimary(
            label: "Speichern",
            onPressed: () async {
              final name = nameController.text;
              if (name.trim().isEmpty) {
                getIt<Toast>().showError("Name darf nicht leer sein.");
                return;
              }
              await getIt<Shortcuts>().saveNewShortcutRoute(name);
              getIt<Toast>().showSuccess("Route gespeichert!");

              if (!context.mounted) return;
              Navigator.pop(context);
            },
            boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
          ),
          BigButtonTertiary(
            label: "Abbrechen",
            addPadding: false,
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

/// Shows a dialog for saving a shortcut location.
void showSaveShortcutLocationSheet(context, Waypoint waypoint) {
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
      final nameController = TextEditingController();
      return DialogLayout(
        title: 'Ort speichern',
        text: "Bitte gib einen Namen an, unter dem der Ort gespeichert werden soll.",
        actions: [
          TextField(
            autofocus: MediaQuery.of(dialogContext).viewInsets.bottom > 0,
            controller: nameController,
            maxLength: 20,
            decoration: InputDecoration(
              hintText: "Zuhause, Arbeit, ...",
              fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              filled: true,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                borderSide: BorderSide.none,
              ),
              suffixIcon: Icon(
                Icons.bookmark,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              counterStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          BigButtonPrimary(
            label: "Speichern",
            onPressed: () async {
              final name = nameController.text;
              if (name.trim().isEmpty) {
                getIt<Toast>().showError("Name darf nicht leer sein.");
                return;
              }
              await getIt<Shortcuts>().saveNewShortcutLocation(name, waypoint);
              await getIt<Geosearch>().addToSearchHistory(waypoint);
              getIt<Toast>().showSuccess("Ort gespeichert!");
              Navigator.pop(context);
            },
            boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
          )
        ],
      );
    },
  );
}

/// Show a sheet to save a shortcut from another shortcut.
void showSaveShortcutFromShortcutSheet(context, {required Shortcut shortcut}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor:
        Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.4),
    transitionBuilder: (context, animation, secondaryAnimation, child) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4 * animation.value, sigmaY: 4 * animation.value),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    ),
    pageBuilder: (BuildContext dialogContext, Animation<double> animation, Animation<double> secondaryAnimation) {
      final nameController = TextEditingController();
      return DialogLayout(
        title: shortcut is ShortcutRoute ? "Route speichern" : "Ort speichern",
        text: shortcut is ShortcutRoute
            ? "Bitte gib einen Namen für die neue Route ein."
            : "Bitte gib einen Namen für den neuen Ort ein.",
        actions: [
          TextField(
            autofocus: false,
            controller: nameController,
            maxLength: 20,
            decoration: InputDecoration(
              hintText: shortcut is ShortcutRoute ? "Importierte Route" : "Importierter Ort",
              fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                color: Theme.of(context).colorScheme.onSurface,
                fill: Colors.transparent,
                // splash: Colors.transparent,
                withBorder: false,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              counterStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          BigButtonPrimary(
            label: "Speichern",
            onPressed: () async {
              final name = nameController.text;
              if (name.trim().isEmpty) {
                getIt<Toast>().showError("Name darf nicht leer sein.");
                return;
              }
              final shortcuts = getIt<Shortcuts>();
              shortcut.name = name;

              await shortcuts.saveNewShortcutObject(shortcut);

              if (!context.mounted) return;
              Navigator.pop(context);
            },
            boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
          ),
          BigButtonTertiary(
            label: "Abbrechen",
            addPadding: false,
            onPressed: () {
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
    barrierColor:
        Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.4),
    transitionBuilder: (context, animation, secondaryAnimation, child) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4 * animation.value, sigmaY: 4 * animation.value),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    ),
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
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: orientation == Orientation.portrait
                ? MediaQuery.of(context).size.width * 0.8
                : MediaQuery.of(context).size.width * 0.6,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              color: Theme.of(context).colorScheme.surface.withOpacity(1),
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
    );
  }
}
