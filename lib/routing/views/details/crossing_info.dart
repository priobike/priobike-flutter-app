import 'dart:io';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/modal.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/status/services/sg.dart';

class CrossingInfo extends StatefulWidget {
  const CrossingInfo({super.key});

  @override
  CrossingInfoState createState() => CrossingInfoState();
}

class CrossingInfoState extends State<CrossingInfo> {
  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The details state of road class.
  bool showTrafficLightDetails = false;

  /// The associated status service, which is injected by the provider.
  late PredictionSGStatus status;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    routing = getIt<Routing>();
    routing.addListener(update);

    status = getIt<PredictionSGStatus>();
    status.addListener(update);
  }

  @override
  void dispose() {
    routing.removeListener(update);
    status.removeListener(update);
    super.dispose();
  }

  /// A callback that is fired when the user wants to select the displayed layers.
  void showCrossingInfoSheet() {
    showAppSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CrossingExplanationView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: RawMaterialButton(
        fillColor: Theme.of(context).colorScheme.surfaceVariant,
        splashColor: Theme.of(context).colorScheme.surfaceTint,
        onPressed: () => showCrossingInfoSheet(),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.07)
                : Colors.black.withOpacity(0.07),
          ),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
        ),
        child: Row(
          children: [
            const HSpace(),
            SizedBox(
              height: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.zero,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color.fromRGBO(0, 255, 106, 1),
                            border: Border.all(color: const Color.fromRGBO(0, 179, 74, 1), width: 1),
                          ),
                        ),
                        const SizedBox(
                          width: 2,
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: Platform.isAndroid ? 4 : 0),
                          child: Small(
                            context: context,
                            text: status.ok.toString(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color.fromRGBO(0, 115, 255, 1),
                          border: Border.all(color: const Color.fromRGBO(0, 69, 150, 1), width: 1),
                        ),
                      ),
                      const SizedBox(
                        width: 3,
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: Platform.isAndroid ? 4 : 0),
                        child: Small(
                          context: context,
                          text: (status.bad + status.offline).toString(),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color.fromRGBO(217, 217, 217, 1),
                          border: Border.all(color: const Color.fromRGBO(152, 152, 152, 1), width: 1),
                        ),
                      ),
                      const SizedBox(
                        width: 3,
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: Platform.isAndroid ? 4 : 0),
                        child: Small(
                          context: context,
                          text: status.disconnected.toString(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 8, top: 12, bottom: 12),
              child: Icon(
                Icons.info_outline,
                size: 32,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrossingExplanationView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          children: [
            const VSpace(),
            Content(
                context: context,
                text:
                    "Um dich bei der Erstellung deiner Route zu unterstützen, zeigen wir dir, welche Kreuzungen auf deiner Strecke liegen."),
            const VSpace(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color.fromRGBO(0, 255, 106, 1),
                    border: Border.all(color: const Color.fromRGBO(0, 179, 74, 1), width: 1),
                  ),
                ),
                const HSpace(),
                Flexible(
                  child: Content(
                    text: "Ampeln, welche im System angebunden sind (entlang der Route)",
                    context: context,
                    maxLines: 5,
                  ),
                ),
              ],
            ),
            const SmallVSpace(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color.fromRGBO(0, 115, 255, 1),
                    border: Border.all(color: const Color.fromRGBO(0, 69, 150, 1), width: 1),
                  ),
                ),
                const HSpace(),
                Flexible(
                  child: Content(
                      text: "Davon Ampeln, welche derzeit über Geschwindigkeitsprognosen verfügen", context: context),
                ),
              ],
            ),
            const VSpace(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color.fromRGBO(217, 217, 217, 1),
                    border: Border.all(color: const Color.fromRGBO(152, 152, 152, 1), width: 1),
                  ),
                ),
                const HSpace(),
                Flexible(
                  child: Content(
                      text:
                          "Weitere Kreuzungen, an welchen Ampeln liegen könnten, welche jedoch nicht im System vorhanden sind.",
                      context: context),
                ),
              ],
            ),
            const VSpace(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color.fromRGBO(196, 220, 248, 1),
                    border: Border.all(color: const Color.fromRGBO(196, 220, 248, 1), width: 1),
                  ),
                ),
                const HSpace(),
                Flexible(
                  child: Content(text: "Alle Kreuzungen, welche im System angebunden sind.", context: context),
                ),
              ],
            ),
            const VSpace(),
          ],
        ),
      ),
    );
  }
}
