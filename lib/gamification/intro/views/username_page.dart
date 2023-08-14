import 'package:flutter/material.dart';
import 'package:flutter/src/animation/animation_controller.dart';
import 'package:flutter/src/widgets/icon_data.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:priobike/common/fx.dart';
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
  Widget get mainContent => const Content();

  @override
  void onBackButtonTab(BuildContext context) => getIt<GameIntroService>().setPrefsSet(false);

  @override
  void onConfirmButtonTab(BuildContext context) => getIt<GameIntroService>().setTutorialFinished(true);
}

class Content extends StatefulWidget {
  const Content({Key? key}) : super(key: key);

  @override
  State<Content> createState() => _ContentState();
}

class _ContentState extends State<Content> {
  Widget _buildInputField() {
    var service = getIt<GameIntroService>();
    return VPad(
      child: TextFormField(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
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
    return SafeArea(
      child: HPad(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 64 + 16),
            Header(text: "Bestimme Deinen Username", context: context),
            const SmallVSpace(),
            SubHeader(text: "Den kannst du nicht mehr ändern Bro!", context: context),
            const SmallVSpace(),
            _buildInputField(),
          ],
        ),
      ),
    );
  }
}
