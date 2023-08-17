import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/gamification/hub/services/profile_service.dart';
import 'package:priobike/gamification/intro/services/intro_service.dart';
import 'package:priobike/gamification/intro/views/intro_page.dart';
import 'package:priobike/main.dart';

/// Intro page which gives the user the option to choose which parts of the gamification
/// functionality they want to active.
class GamePrefsPage extends StatelessWidget {
  /// Controller which handles the appear animation.
  final AnimationController animationController;

  const GamePrefsPage({Key? key, required this.animationController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GameIntroPage(
      animationController: animationController,
      confirmButtonLabel: "Auswahl Bestätigen",
      onBackButtonTab: () => getIt<GameIntroService>().setStartedIntro(false),
      onConfirmButtonTab: () => getIt<GameIntroService>().setPrefsSet(true),
      contentList: [
        const SizedBox(height: 64 + 16),
        Header(text: "Wähle deine Preferenzen:", context: context),
        SubHeader(text: "Keine Angst, du kannst deine Auswahl später noch ändern", context: context),
        const GamePrefListElement(
          label: "Fahrt-Statistiken anzeigen",
          prefKey: UserProfileService.presRideStatisticsKey,
        ),
        const SizedBox(height: 82),
      ],
    );
  }
}

/// This widget displays a possible preference which the user can enable or disable by tapping on it.
class GamePrefListElement extends StatefulWidget {
  final String label;

  final String prefKey;

  const GamePrefListElement({
    Key? key,
    required this.label,
    required this.prefKey,
  }) : super(key: key);

  @override
  State<GamePrefListElement> createState() => _GamePrefListElementState();
}

class _GamePrefListElementState extends State<GamePrefListElement> {
  /// The associated intro service, which is injected by the provider.
  late GameIntroService introService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    setState(() {});
  }

  @override
  void initState() {
    introService = getIt<GameIntroService>();
    introService.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    introService.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var service = getIt<GameIntroService>();
    var selected = service.stringInPrefs(widget.prefKey);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Tile(
        showShadow: false,
        borderWidth: 3,
        borderColor: selected ? theme.colorScheme.primary : Colors.grey.withOpacity(0.25),
        splash: Colors.grey.withOpacity(0.1),
        fill: theme.colorScheme.background,
        onPressed: () => service.addOrRemoveFromPrefs(widget.prefKey),
        content: Center(
          child: SubHeader(
            text: widget.label,
            context: context,
          ),
        ),
      ),
    );
  }
}
