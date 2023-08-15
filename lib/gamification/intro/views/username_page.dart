import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/intro/services/intro_service.dart';
import 'package:priobike/gamification/intro/views/intro_page.dart';
import 'package:priobike/main.dart';

class GameUsernamePage extends GameIntroPage {
  const GameUsernamePage({Key? key, required AnimationController controller}) : super(key: key, controller: controller);

  @override
  IconData get confirmButtonIcon => Icons.check;

  @override
  String get confirmButtonLabel => "Beitreten";

  @override
  bool get withContentFade => false;

  @override
  void onBackButtonTab(BuildContext context) => getIt<GameIntroService>().setPrefsSet(false);

  @override
  void onConfirmButtonTab(BuildContext context) => getIt<GameIntroService>().setTutorialFinished(true);

  @override
  List<Widget> getContentElements(BuildContext context) => [
        const SizedBox(height: 64 + 16),
        Header(text: "Bestimme Deinen Username", context: context),
        const SmallVSpace(),
        SubHeader(text: "Den kannst du nicht mehr ändern Bro!", context: context),
        const SmallVSpace(),
        _buildInputField(),
      ];

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
}
