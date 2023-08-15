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

  final GlobalKey<FormState> _textFormKey = GlobalKey<FormState>();

  final GameIntroService service = getIt<GameIntroService>();

  GameUsernamePage({Key? key, required this.animationController}) : super(key: key);

  Widget _buildInputField(BuildContext context) {
    return VPad(
      child: Form(
        key: _textFormKey,
        child: TextFormField(
          decoration: InputDecoration(
            errorMaxLines: 2,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.red,
                width: 3,
              ),
              borderRadius: BorderRadius.all(
                Radius.circular(24),
              ),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.red,
                width: 3,
              ),
              borderRadius: BorderRadius.all(
                Radius.circular(24),
              ),
            ),
            hintText: 'Benutzername',
          ),
          style: Theme.of(context).textTheme.titleMedium!,
          initialValue: service.username,
          maxLines: 1,
          validator: (value) {
            if (value == null || value.length < 4) {
              return 'Dein Username muss mindestens 4 Zeichen lang sein!';
            } else if (value.length > 20) {
              return 'Dein Username darf höchstens 20 Zeichen lang sein!';
            }
            service.setUsername(value);
            return null;
          },
          onFieldSubmitted: (value) => _textFormKey.currentState!.validate(),
        ),
      ),
    );
  }

  Widget _getLoadingWidget(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          color: Colors.black.withOpacity(0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(),
            ),
            Text(
              "Profil wird erstellt...",
              style: Theme.of(context).textTheme.headlineSmall!.apply(color: Colors.white),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GameIntroPage(
          animationController: animationController,
          confirmButtonLabel: "Beitreten",
          withContentFade: false,
          onBackButtonTab: () => getIt<GameIntroService>().setPrefsSet(false),
          onConfirmButtonTab: service.loading
              ? null
              : () {
                  if (_textFormKey.currentState == null) return;
                  var validInput = _textFormKey.currentState!.validate();
                  if (validInput) getIt<GameIntroService>().finishIntro();
                },
          contentList: [
            const SizedBox(height: 64 + 16),
            Header(text: "Bestimme Deinen Username", context: context),
            const SmallVSpace(),
            SubHeader(text: "Den kannst du nicht mehr ändern Bro!", context: context),
            const SmallVSpace(),
            _buildInputField(context),
          ],
        ),
        service.loading ? _getLoadingWidget(context) : Stack(),
      ],
    );
  }
}
