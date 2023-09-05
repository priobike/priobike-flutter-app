import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/hub/views/main.dart';
import 'package:priobike/gamification/intro/views/game_intro.dart';
import 'package:priobike/gamification/profile/services/profile_service.dart';
import 'package:priobike/gamification/profile/views/profile_card.dart';
import 'package:priobike/main.dart';

class GameHomeCard extends StatefulWidget {
  const GameHomeCard({Key? key}) : super(key: key);

  @override
  State<GameHomeCard> createState() => _GameHomeCardState();
}

class _GameHomeCardState extends State<GameHomeCard> {
  /// The associated intro service, which is injected by the provider.
  late GameProfileService _profileService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  @override
  void initState() {
    // Add listener to game intro service, which manages the whole intro process.
    _profileService = getIt<GameProfileService>();
    _profileService.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    _profileService.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_profileService.hasProfile) {
      return const GameProfileCard();
    } else {
      return infoCard;
    }
  }

  Widget get profileCard => GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GameHubView())),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: const BorderRadius.all(Radius.circular(24)),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            width: MediaQuery.of(context).size.width,
            child: Row(
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BoldContent(text: "PrioBike Challenge", context: context),
                      const SizedBox(height: 4),
                      Small(text: "Dein aktueller Fortschritt", context: context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget get infoCard => Padding(
        padding: const EdgeInsets.only(top: 24),
        child: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GameIntro())),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              borderRadius: const BorderRadius.all(Radius.circular(24)),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              width: MediaQuery.of(context).size.width,
              child: Row(
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BoldContent(text: "PrioBike Plus", context: context),
                        const SizedBox(height: 4),
                        Small(text: "Klingt irgendwie, als würd das was kosten.", context: context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
