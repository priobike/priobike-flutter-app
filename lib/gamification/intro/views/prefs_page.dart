import 'package:flutter/material.dart';
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/gamification/intro/services/intro_service.dart';
import 'package:priobike/gamification/intro/views/intro_page.dart';
import 'package:priobike/main.dart';

class GamePrefsPage extends GameIntroPage {
  final Function onBackButton;

  const GamePrefsPage(this.onBackButton, {Key? key, required AnimationController controller})
      : super(key: key, controller: controller);

  @override
  IconData get confirmButtonIcon => Icons.check;

  @override
  String get confirmButtonLabel => "Auswahl Bestätigen";

  @override
  void onBackButtonTab(BuildContext context) => onBackButton;

  @override
  void onConfirmButtonTab(BuildContext context) => getIt<GameIntroService>().confirmPreferences();

  @override
  Widget buildMainContent(BuildContext context) {
    return HPad(
      child: Fade(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 164),
              SubHeader(text: "Wähle deine Preferenzen:", context: context),
              const GamePrefListElement(label: "Test1"),
              const GamePrefListElement(label: "Test2"),
              const GamePrefListElement(label: "Test3"),
              const GamePrefListElement(label: "Test4"),
              const GamePrefListElement(label: "Test5"),
              const GamePrefListElement(label: "Test6"),
              const SizedBox(height: 164),
            ],
          ),
        ),
      ),
    );
  }
}

class GamePrefListElement extends StatefulWidget {
  final String label;

  //final Function onTap;

  const GamePrefListElement({
    Key? key,
    required this.label,
    //required this.onTap,
  }) : super(key: key);

  @override
  State<GamePrefListElement> createState() => _GamePrefListElementState();
}

class _GamePrefListElementState extends State<GamePrefListElement> {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Tile(
        splash: theme.primaryColor,
        fill: Colors.white,
        onPressed: () {
          log.w("${widget.label} pressed");
        },
        content: Center(child: Text(widget.label)),
      ),
    );
  }
}
