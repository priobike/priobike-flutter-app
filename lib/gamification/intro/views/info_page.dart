import 'package:flutter/material.dart';
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/hub/views/main.dart';
import 'package:priobike/gamification/intro/services/intro_service.dart';
import 'package:priobike/main.dart';

class GameInfoPage extends StatefulWidget {
  const GameInfoPage({Key? key}) : super(key: key);

  @override
  State<GameInfoPage> createState() => _GameInfoPageState();
}

class _GameInfoPageState extends State<GameInfoPage> {
  /// The associated intro service, which is injected by the provider.
  late GameIntroService introService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    introService = getIt<GameIntroService>();
    introService.addListener(update);
  }

  @override
  void dispose() {
    introService.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (introService.alreadyJoined) return const GamificationHubView();

    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: HPad(
                child: Fade(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 164),
                        Header(text: "Gamification", context: context),
                        const SmallVSpace(),
                        SubHeader(text: "Möchtest Du an unserem PrioBike-Spiel teilnehmen?", context: context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      AppBackButton(onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Pad(
                child: BigButton(
                  icon: Icons.check,
                  iconColor: Colors.white,
                  label: "Teilnehmen",
                  onPressed: introService.joinGame,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
