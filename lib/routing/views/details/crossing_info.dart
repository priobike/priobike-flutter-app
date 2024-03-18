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

  /// Whether the crossing info should be shown.
  bool showInfo = false;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    setState(() {
      showInfo = !routing.isFetchingRoute && routing.selectedRoute != null;
    });
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: showCrossingInfoSheet,
          child: Container(
            width: 58,
            constraints: const BoxConstraints(minHeight: 58),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.all(
                Radius.circular(24),
              ),
            ),
            child: AnimatedCrossFade(
              crossFadeState: showInfo ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 1000),
              firstCurve: Curves.easeInOutCubic,
              secondCurve: Curves.easeInOutCubic,
              sizeCurve: Curves.easeInOutCubic,
              secondChild: Container(),
              firstChild: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
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
                        color: CI.route,
                        border: Border.all(color: CI.routeBackground, width: 2),
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(top: Platform.isAndroid ? 3 : 0),
                        child: Center(
                          child: BoldSmall(
                            context: context,
                            text: routing.isFetchingRoute
                                ? "-"
                                : (routing.selectedRoute!.bad + routing.selectedRoute!.offline).toString(),
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
                        border: Border.all(color: CI.radkulturGreen, width: 2),
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(top: Platform.isAndroid ? 3 : 0),
                        child: Center(
                          child: BoldSmall(
                            context: context,
                            text: routing.isFetchingRoute ? "-" : routing.selectedRoute!.ok.toString(),
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
                        border: Border.all(color: const Color.fromRGBO(152, 152, 152, 1), width: 2),
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(top: Platform.isAndroid ? 3 : 0),
                        child: Center(
                          child: BoldSmall(
                            context: context,
                            text: routing.isFetchingRoute ? "-" : routing.selectedRoute!.disconnected.toString(),
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SmallVSpace(),
                  ],
                ),
              ),
            ),
          ),
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
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: Column(
          children: [
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
                      child: Content(
                        text: "Ausgewählte Route",
                        context: context,
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
                      child: Content(
                        text: "Alternative Route",
                        context: context,
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
                        color: const Color.fromRGBO(0, 255, 106, 1),
                      ),
                    ),
                    const SmallHSpace(),
                    Flexible(
                      child: Content(
                        text: "Prognosen vorhanden",
                        context: context,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 32,
                      height: 8,
                      child: CustomPaint(
                        painter: GetOffBikeLegendPainter(
                          context: context,
                        ),
                        child: const SizedBox(
                          height: 32,
                          width: 8,
                        ),
                      ),
                    ),
                    const SmallHSpace(),
                    Flexible(
                      child: Content(
                        text: "Absteigen",
                        context: context,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const VSpace(),
            Row(
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
                const HSpace(),
                Flexible(
                  child: Content(text: "Ampeln entlang Deiner Route mit Geschwindigkeitsempfehlung.", context: context),
                ),
              ],
            ),
            const VSpace(),
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
                const HSpace(),
                Flexible(
                  child: Content(
                    text:
                        "Weitere angebundene Ampeln entlang Deiner Route, die aktuell jedoch keine Geschwindigkeitsempfehlung haben.",
                    context: context,
                    maxLines: 5,
                  ),
                ),
              ],
            ),
            const VSpace(),
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
                const HSpace(),
                Flexible(
                  child: Content(
                      text:
                          "Weitere Kreuzungen, an welchen Ampeln liegen könnten, die jedoch nicht im System angebunden sind.",
                      context: context),
                ),
              ],
            ),
            const VSpace(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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

class GetOffBikeLegendPainter extends CustomPainter {
  final BuildContext context;

  GetOffBikeLegendPainter({required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    Paint frontPaint = Paint()..color = const Color.fromRGBO(0, 255, 106, 1);
    final frontPath = Path()
      ..moveTo(size.width * 0.36, 0)
      ..lineTo(size.width * 0.3, size.height)
      ..lineTo(size.width * 0.15, size.height)
      ..cubicTo(0, size.height, 0, size.height * 0.5, 0, size.height * 0.5)
      ..cubicTo(0, 0, size.width * 0.15, 0, size.width * 0.15, 0)
      ..lineTo(size.width * 0.36, 0);

    Paint middlePaint = Paint()..color = CI.route;
    final middlePath = Path()
      ..moveTo(size.width * 0.36, 0)
      ..lineTo(size.width * 0.3, size.height)
      ..lineTo(size.width * 0.63, size.height)
      ..lineTo(size.width * 0.69, 0)
      ..lineTo(size.width * 0.36, 0);

    Paint backPaint = Paint()..color = CI.secondaryRoute;
    final backPath = Path()
      ..moveTo(size.width * 0.69, 0)
      ..lineTo(size.width * 0.63, size.height)
      ..lineTo(size.width * 0.85, size.height)
      ..cubicTo(size.width, size.height, size.width, size.height * 0.5, size.width, size.height * 0.5)
      ..cubicTo(size.width, 0, size.width * 0.85, 0, size.width * 0.85, 0)
      ..lineTo(size.width * 0.69, 0);

    Paint dashedPaint = Paint()..color = Colors.black;

    // Draw the front path;
    canvas.drawPath(frontPath, frontPaint);
    // Draw the middle path.
    canvas.drawPath(middlePath, middlePaint);
    // Draw the back path.
    canvas.drawPath(backPath, backPaint);

    // Draw the dash.
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.15, size.height * 0.15, size.width * 0.25, size.height * 0.7),
            const Radius.circular(4.0)),
        dashedPaint);

    // Draw the dashed part 2.
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.55, size.height * 0.15, size.width * 0.25, size.height * 0.7),
            const Radius.circular(4.0)),
        dashedPaint);
  }

  @override
  bool shouldRepaint(GetOffBikeLegendPainter oldDelegate) {
    return false;
  }
}
