import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/gamification/intro/services/intro_service.dart';
import 'package:priobike/gamification/intro/views/intro_page.dart';
import 'package:priobike/main.dart';

class GamePrefsPage extends GameIntroPage {
  const GamePrefsPage({Key? key, required AnimationController controller}) : super(key: key, controller: controller);

  @override
  IconData get confirmButtonIcon => Icons.check;

  @override
  String get confirmButtonLabel => "Auswahl Bestätigen";

  @override
  bool get withContentFade => true;

  @override
  void onBackButtonTab(BuildContext context) => getIt<GameIntroService>().setStartedIntro(false);

  @override
  void onConfirmButtonTab(BuildContext context) => getIt<GameIntroService>().setPrefsSet(true);

  @override
  List<Widget> getContentElements(BuildContext context) => [
        const SizedBox(height: 64 + 16),
        Header(text: "Wähle deine Preferenzen:", context: context),
        SubHeader(text: "Keine Angst, du kannst deine Auswahl später noch ändern", context: context),
        const GamePrefListElement(
          label: "Das hier ist Test 1",
          prefKey: GameIntroService.prefKeyTest1,
        ),
        const GamePrefListElement(
          label: "Test 2 ist hier",
          prefKey: GameIntroService.prefKeyTest2,
        ),
        const GamePrefListElement(
          label: "Achtung Achtung Test 3",
          prefKey: GameIntroService.prefKeyTest3,
        ),
        const GamePrefListElement(
          label: "Heyhey Test 4 hier",
          prefKey: GameIntroService.prefKeyTest4,
        ),
        const GamePrefListElement(
          label: "Nennen wir das hier Test 5",
          prefKey: GameIntroService.prefKeyTest5,
        ),
        const GamePrefListElement(
          label: "Könnte Test 6 sein",
          prefKey: GameIntroService.prefKeyTest6,
        ),
        const SizedBox(height: 82),
      ];
}

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
