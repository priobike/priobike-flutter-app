import 'package:flutter/material.dart';
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/spacing.dart';
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
  Widget get mainContent => const Content();

  @override
  void onBackButtonTab(BuildContext context) => getIt<GameIntroService>().setStartedIntro(false);

  @override
  void onConfirmButtonTab(BuildContext context) => getIt<GameIntroService>().setPrefsSet(true);
}

class Content extends StatelessWidget {
  const Content({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: HPad(
        child: Fade(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 64 + 16),
                Header(text: "Wähle deine Preferenzen:", context: context),
                const GamePrefListElement(
                  label: "Test1",
                  prefKey: GameIntroService.prefKeyTest1,
                ),
                const GamePrefListElement(
                  label: "Test2",
                  prefKey: GameIntroService.prefKeyTest2,
                ),
                const GamePrefListElement(
                  label: "Test3",
                  prefKey: GameIntroService.prefKeyTest3,
                ),
                const GamePrefListElement(
                  label: "Test4",
                  prefKey: GameIntroService.prefKeyTest4,
                ),
                const GamePrefListElement(
                  label: "Test5",
                  prefKey: GameIntroService.prefKeyTest5,
                ),
                const GamePrefListElement(
                  label: "Test6",
                  prefKey: GameIntroService.prefKeyTest6,
                ),
                const SizedBox(height: 164),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
        splash: selected ? Colors.white : theme.primaryColor,
        fill: selected ? theme.primaryColor : Colors.white,
        onPressed: () => service.addOrRemoveFromPrefs(widget.prefKey),
        content: Center(child: Text(widget.label)),
      ),
    );
  }
}
