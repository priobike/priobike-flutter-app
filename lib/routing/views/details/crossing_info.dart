import 'dart:io';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/modal.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
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
      showDragHandle: true,
      builder: (_) => _CrossingExplanationView(),
    );
  }

  /// The widget that is shown, when the info should be hidden.
  Widget _hideInfo() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: const BorderRadius.all(
          Radius.circular(24),
        ),
      ),
    );
  }

  /// The info widget.
  Widget _showInfo() {
    return Container(
      width: 58,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: const BorderRadius.all(
          Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(
            height: 58,
          ),
          const SmallVSpace(),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromRGBO(0, 115, 255, 1),
              border: Border.all(color: const Color.fromRGBO(0, 69, 150, 1), width: 1),
            ),
            child: Padding(
              padding: EdgeInsets.only(top: Platform.isAndroid ? 3 : 0),
              child: Center(
                child: Small(
                  context: context,
                  text: routing.isFetchingRoute ? "-" : (status.bad + status.offline).toString(),
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SmallVSpace(),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromRGBO(0, 255, 106, 1),
              border: Border.all(color: const Color.fromRGBO(0, 179, 74, 1), width: 1),
            ),
            child: Padding(
              padding: EdgeInsets.only(top: Platform.isAndroid ? 3 : 0),
              child: Center(
                child: Small(
                  context: context,
                  text: routing.isFetchingRoute ? "-" : status.ok.toString(),
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SmallVSpace(),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromRGBO(217, 217, 217, 1),
              border: Border.all(color: const Color.fromRGBO(152, 152, 152, 1), width: 1),
            ),
            child: Padding(
              padding: EdgeInsets.only(top: Platform.isAndroid ? 3 : 0),
              child: Center(
                child: Small(
                  context: context,
                  text: routing.isFetchingRoute ? "-" : status.disconnected.toString(),
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SmallVSpace(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 1000),
          sizeCurve: Curves.easeInOutCubic,
          firstChild: _hideInfo(),
          secondChild: _showInfo(),
          crossFadeState: routing.isFetchingRoute || routing.selectedRoute == null
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
        ),
        SizedBox(
          width: 58,
          height: 58,
          child: Tile(
            fill: Theme.of(context).colorScheme.surfaceVariant,
            onPressed: showCrossingInfoSheet,
            content: Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
        ),
      ],
    );
  }
}

class _CrossingExplanationView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            Content(text: "Legende", context: context),
            const SmallVSpace(),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 5 / 1,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: CI.route,
                      ),
                    ),
                    const SmallHSpace(),
                    Flexible(
                      child: Text(
                        "Ausgewählte Route",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: CI.secondaryRoute,
                      ),
                    ),
                    const SmallHSpace(),
                    Flexible(
                      child: Text(
                        "Alternative Route",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: CI.radkulturGreen,
                      ),
                    ),
                    const SmallHSpace(),
                    Flexible(
                      child: Text(
                        "Prognosen vorhanden",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 32,
                      height: 8,
                      child: Row(
                        children: List.generate(
                          70 ~/ 10,
                          (index) => Expanded(
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: index % 2 == 0 ? Colors.transparent : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SmallHSpace(),
                    Flexible(
                      child: Text(
                        "Absteigen",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
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
                    color: const Color.fromRGBO(0, 115, 255, 1),
                    border: Border.all(color: const Color.fromRGBO(0, 69, 150, 1), width: 1),
                  ),
                ),
                const HSpace(),
                Flexible(
                  child: Content(
                    text: "Ampeln, welche im System angebunden sind (entlang deiner Route)",
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
                    color: const Color.fromRGBO(0, 255, 106, 1),
                    border: Border.all(color: const Color.fromRGBO(0, 179, 74, 1), width: 1),
                  ),
                ),
                const HSpace(),
                Flexible(
                  child: Content(
                      text: "Davon Ampeln, welche derzeit über Geschwindigkeitsempfehlungen verfügen",
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
                    color: isDark ? const Color.fromRGBO(0, 75, 130, 1) : const Color.fromRGBO(196, 220, 248, 1),
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
