import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/intro/services/intro_service.dart';
import 'package:priobike/gamification/intro/views/intro_page.dart';
import 'package:priobike/main.dart';

/// Intro page which provides the user with the option to enter a username.
class GameUsernamePage extends StatelessWidget {
  /// Controller which handles the appear animation.
  final AnimationController animationController;

  const GameUsernamePage({Key? key, required this.animationController}) : super(key: key);

  Widget _buildInputField() {
    var service = getIt<GameIntroService>();
    return VPad(
      child: TextFormField(
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.25),
              width: 3,
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(24),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.25),
              width: 3,
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(24),
            ),
          ),
          hintText: 'Gib deinen Benutzernamen ein',
        ),
        initialValue: service.username,
        onChanged: (value) => service.setUsername(value),
        maxLines: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameIntroPage(
      animationController: animationController,
      confirmButtonLabel: "Beitreten",
      withContentFade: false,
      onBackButtonTab: () => getIt<GameIntroService>().setPrefsSet(false),
      onConfirmButtonTab: () => getIt<GameIntroService>().finishTutorial(),
      contentList: [
        const SizedBox(height: 64 + 16),
        Header(text: "Bestimme Deinen Username", context: context),
        const SmallVSpace(),
        SubHeader(text: "Den kannst du nicht mehr ändern Bro!", context: context),
        const SmallVSpace(),
        _buildInputField(),
      ],
    );
  }
}
