import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/views/custom_dialog.dart';
import 'package:priobike/gamification/common/views/dialog_button.dart';
import 'package:priobike/gamification/goals/models/route_goals.dart';
import 'package:priobike/gamification/goals/services/goals_service.dart';
import 'package:priobike/gamification/goals/views/weekday_button.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/home/views/shortcuts/selection.dart';
import 'package:priobike/main.dart';

/// Dialog to edit the route goals set by the user.
class EditRouteGoalsDialog extends StatefulWidget {
  const EditRouteGoalsDialog({Key? key}) : super(key: key);

  @override
  State<EditRouteGoalsDialog> createState() => _EditRouteGoalsDialogState();
}

class _EditRouteGoalsDialogState extends State<EditRouteGoalsDialog> {
  /// The associated shortcuts service to display the users saved shortcuts as possible routes to set goals for.
  late Shortcuts _shortcutsService;

  /// The shortcut (to a route) currently selected by the user.
  Shortcut? _selectedShortcut;

  /// A list of bools which signifies on which weekdays the user wants to drive the selected route.
  late List<bool> _weekdays;

  /// Get list of exisiting shortcuts from corresponding service.
  List<Shortcut> get _shortcuts => _shortcutsService.shortcuts?.toList() ?? [];

  /// Check whether the user has selected any days to drive a route on.
  bool get _noDaysSelected => _weekdays.where((day) => day).isEmpty;

  @override
  void initState() {
    var goals = getIt<GoalsService>().routeGoals;
    _weekdays = List.from(goals?.weekdays ?? List.filled(7, false));
    _shortcutsService = getIt<Shortcuts>();
    _shortcutsService.addListener(update);
    _selectedShortcut = _shortcuts.where((s) => s.id == goals?.routeID).firstOrNull;
    super.initState();
  }

  @override
  void dispose() {
    _shortcutsService.removeListener(update);
    super.dispose();
  }

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  /// Widget to inform the user that they need to create routes, if they want to set goals for them.
  Widget get _noRoutesWidget => CustomDialog(
        backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.9),
        horizontalMargin: 16,
        content: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: SubHeader(
                  text: 'Du kannst Dir eigene Routenziele setzen, sobald Du Deine erste eigene Route erstellt hast.',
                  context: context,
                  textAlign: TextAlign.center,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_shortcuts.isEmpty) return _noRoutesWidget;
    const double shortcutRightPad = 16;
    final shortcutWidth = (MediaQuery.of(context).size.width / 2) - shortcutRightPad;
    return CustomDialog(
      horizontalMargin: 16,
      content: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SmallVSpace(),
            BoldSubHeader(
              text: 'Möchtest Du Dir vornehmen eine Deiner Routen regelmäßig zu fahren?',
              context: context,
              textAlign: TextAlign.center,
            ),
            const SmallVSpace(),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _weekdays
                  .mapIndexed(
                    (i, day) => WeekdayButton(
                      day: i,
                      onPressed: _selectedShortcut == null
                          ? null
                          : () {
                              _weekdays[i] = !_weekdays[i];
                              if (_noDaysSelected) _selectedShortcut = null;
                              setState(() {});
                            },
                      selected: day,
                    ),
                  )
                  .toList(),
            ),
            const VSpace(),
            SingleChildScrollView(
              padding: const EdgeInsets.only(left: 8),
              controller: ScrollController(),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _shortcuts
                    .map(
                      (shortcut) => ShortcutView(
                        onPressed: () {
                          if (_selectedShortcut == shortcut) {
                            setState(() {
                              _selectedShortcut = null;
                              _weekdays = List.filled(7, false);
                            });
                          } else if (_selectedShortcut == null) {
                            setState(() {
                              _selectedShortcut = shortcut;
                              _weekdays = [true, true, true, true, true, false, false];
                            });
                          } else {
                            setState(() => _selectedShortcut = shortcut);
                          }
                        },
                        shortcut: shortcut,
                        // width == height to make it a square
                        width: shortcutWidth,
                        height: shortcutWidth,
                        rightPad: shortcutRightPad,
                        selected: _selectedShortcut == shortcut,
                        showSplash: false,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SmallVSpace(),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SmallHSpace(),
                CustomDialogButton(
                  label: 'Abbrechen',
                  onPressed: () => Navigator.of(context).pop(),
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.25),
                ),
                const SmallHSpace(),
                CustomDialogButton(
                  label: 'Speichern',
                  onPressed: () {
                    RouteGoals? goals;
                    if (!_noDaysSelected && _selectedShortcut != null) {
                      goals = RouteGoals(_selectedShortcut!.id, _selectedShortcut!.name, _weekdays);
                    }
                    getIt<GoalsService>().updateRouteGoals(goals);
                    Navigator.of(context).pop();
                  },
                  color: CI.radkulturRed,
                ),
                const SmallHSpace(),
              ],
            ),
            const SmallVSpace(),
          ],
        ),
      ),
    );
  }
}
