import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/icon_item.dart';
import 'package:priobike/common/layout/loading_screen.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

/// A view that displays the user transfer view.
class UserTransferView extends StatefulWidget {
  final Widget? child;

  /// Create the user transfer view.
  const UserTransferView({this.child, super.key});

  @override
  UserTransferViewState createState() => UserTransferViewState();
}

class UserTransferViewState extends State<UserTransferView> {
  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// Is user transferring. Needs to be local variable so that this view doesn't get called in the widget tree again on user transfer in settings.
  bool isUserTransferring = false;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    settings = getIt<Settings>();
    settings.addListener(update);
  }

  @override
  void dispose() {
    settings.removeListener(update);
    super.dispose();
  }

  /// A callback that is executed when the unsubscribe beta button was pressed.
  Future<void> onUnsubscribeBetaPressed() async {
    // Get beta shortcuts before backend switch.
    setState(() {
      isUserTransferring = true;
    });
    await settings.setBackend(Backend.release);
    setState(() {
      isUserTransferring = false;
    });
  }

  /// A callback that is executed when the stay beta button was pressed.
  Future<void> onStayBetaButtonPressed() async {
    // Set did view user transfer screen.
    await settings.setDidViewUserTransfer(true);
  }

  @override
  Widget build(BuildContext context) {
    // Display when backend ist not release and user did not seen this view yet.
    if ((settings.didViewUserTransfer == true || settings.backend != Backend.production) &&
        (!isUserTransferring) &&
        (widget.child != null)) {
      return widget.child!;
    }

    var frame = MediaQuery.of(context);

    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.background,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            HPad(
              child: Fade(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: frame.padding.top + 24),
                      Header(text: "Jetzt umsteigen.", color: CI.radkulturRed, context: context),
                      Header(
                          text: "Wechsle zur stabilen Version der PrioBike-App.",
                          color: CI.radkulturRed,
                          context: context),
                      const VSpace(),
                      BoldContent(text: "Du verwendest aktuell die Beta-Version der PrioBike-App.", context: context),
                      const VSpace(),
                      Content(text: "Du hast jetzt die Möglichkeit umzusteigen.", context: context),
                      Content(text: "Damit bekommst du folgende Vorteile.", context: context),
                      const SmallVSpace(),
                      const VSpace(),
                      IconItem(
                          icon: Icons.traffic,
                          text: "Verwende nur Ampeln, welche regelmäßig Daten schicken.",
                          context: context),
                      const SmallVSpace(),
                      IconItem(
                          icon: Icons.settings_applications,
                          text: "Verwende alle PrioBike-Services in der stabilen Version.",
                          context: context),
                      const VSpace(),
                      const SmallVSpace(),
                      Content(
                          text: "Du kannst jederzeit zwischen der stabilen und der Beta-Version wechseln.",
                          context: context),
                      const SmallVSpace(),
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: "Wähle dafür einfach unter ",
                            style: Theme.of(context).textTheme.displayMedium!.merge(
                                  const TextStyle(fontWeight: FontWeight.normal),
                                ),
                          ),
                          TextSpan(text: "Einstellungen > Version ", style: Theme.of(context).textTheme.displayMedium!),
                          TextSpan(
                            text: "die gewünschte Version aus.",
                            style: Theme.of(context).textTheme.displayMedium!.merge(
                                  const TextStyle(fontWeight: FontWeight.normal),
                                ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 256),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.child == null)
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
            if (widget.child != null)
              Pad(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    BigButton(
                      label: "Beta-Version deabonnieren",
                      onPressed: onUnsubscribeBetaPressed,
                      boxConstraints: const BoxConstraints(minWidth: 320.0, minHeight: 36.0),
                    ),
                    BigButton(
                      fillColor: Theme.of(context).colorScheme.secondary,
                      label: "Beta Tester bleiben",
                      onPressed: onStayBetaButtonPressed,
                      boxConstraints: const BoxConstraints(minWidth: 320.0, minHeight: 36.0),
                    ),
                  ],
                ),
              ),
            if (isUserTransferring) const LoadingScreen()
          ],
        ),
      ),
    );
  }
}