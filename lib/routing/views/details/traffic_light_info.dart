import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/status/services/sg.dart';

class TrafficLightInfo extends StatefulWidget {
  const TrafficLightInfo({super.key});

  @override
  TrafficLightInfoState createState() => TrafficLightInfoState();
}

class TrafficLightInfoState extends State<TrafficLightInfo> {
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

  @override
  Widget build(BuildContext context) {
    if (routing.selectedRoute == null) return Container();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme
            .of(context)
            .colorScheme
            .onTertiary
            .withOpacity(0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () =>
                setState(() {
                  showTrafficLightDetails = !showTrafficLightDetails;
                }),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Content(text: "Ampeln", context: context),
              const HSpace(),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _TrafficLightInfoWidget(
                      assetName: "online",
                      numberTrafficLights: status.ok + status.bad + status.offline,
                    ),
                    const SmallHSpace(),
                    _TrafficLightInfoWidget(
                      assetName: "online-green",
                      numberTrafficLights: status.ok,
                      textColor: CI.radkulturGreen,
                    ),
                    const HSpace(),
                    _TrafficLightInfoWidget(
                      assetName: "disconnected",
                      numberTrafficLights: status.disconnected,
                    ),
                  ],
                ),
              ),
              const HSpace(),
              SizedBox(
                width: 40,
                height: 40,
                child: SmallIconButtonTertiary(
                  icon: showTrafficLightDetails ? Icons.keyboard_arrow_up_sharp : Icons.keyboard_arrow_down_sharp,
                  onPressed: () =>
                      setState(() {
                        showTrafficLightDetails = !showTrafficLightDetails;
                      }),
                ),
              ),
            ]),
          ),
          AnimatedCrossFade(
            firstCurve: Curves.easeInOutCubic,
            secondCurve: Curves.easeInOutCubic,
            sizeCurve: Curves.easeInOutCubic,
            duration: const Duration(milliseconds: 1000),
            firstChild: GestureDetector(
              onTap: () =>
                  setState(() {
                    showTrafficLightDetails = !showTrafficLightDetails;
                  }),
              child: const _TrafficLightInfoDetailWidget(),
            ),
            secondChild: Container(),
            crossFadeState: showTrafficLightDetails ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          ),
          // const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// The traffic light info widget for the traffic light row.
class _TrafficLightInfoWidget extends StatelessWidget {
  /// The name of the asset image.
  final String assetName;

  /// The number of traffic lights of this type.
  final int numberTrafficLights;

  /// The color of the text.
  final Color? textColor;

  const _TrafficLightInfoWidget({required this.assetName, required this.numberTrafficLights, this.textColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    String assetPath = "assets/images/trafficlights/$assetName-${isDark ? "dark" : "light"}-info.png";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(top: Platform.isAndroid ? 8 : 0),
          child: Text(
            numberTrafficLights.toString(),
            style: TextStyle(
              color: textColor,
              fontFamily: 'HamburgSans',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 30,
          child: assetName == "online-green"
              ? _AnimatedTrafficLightIcon(
            isDark: isDark,
          )
              : Image.asset(assetPath),
        ),
      ],
    );
  }
}

/// The traffic light info widget for the traffic light row.
class _TrafficLightInfoDetailWidget extends StatelessWidget {

  const _TrafficLightInfoDetailWidget();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    String assetPathDisconnected = "assets/images/trafficlights/disconnected-${isDark ? "dark" : "light"}-info.png";
    String assetPathConnected = "assets/images/trafficlights/online-${isDark ? "dark" : "light"}-info.png";

    return Column(
      children: [
        const SmallVSpace(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              child: Image.asset(assetPathConnected),
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
            SizedBox(
              height: 24,
              child: _AnimatedTrafficLightIcon(
                isDark: isDark,
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
            SizedBox(
              height: 24,
              child: Image.asset(assetPathDisconnected),
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
      ],
    );
  }
}

/// The traffic light info widget for the traffic light row.
class _AnimatedTrafficLightIcon extends StatefulWidget {
  /// The bool that holds the state of the theme brightness.
  final bool isDark;

  const _AnimatedTrafficLightIcon({required this.isDark});

  @override
  _AnimatedTrafficLightIconState createState() => _AnimatedTrafficLightIconState();
}

class _AnimatedTrafficLightIconState extends State<_AnimatedTrafficLightIcon> {
  late String assetPathRedLight;

  late String assetPathGreenLight;

  double opacityRedLight = 0;

  double opacityGreenLight = 1;

  Timer? animationTimer;

  @override
  void initState() {
    super.initState();

    assetPathRedLight = "assets/images/trafficlights/online-red-${widget.isDark ? "dark" : "light"}-info.png";
    assetPathGreenLight = "assets/images/trafficlights/online-green-${widget.isDark ? "dark" : "light"}-info.png";

    animationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final tmpOpacity = opacityRedLight;
      setState(() {
        opacityRedLight = opacityGreenLight;
        opacityGreenLight = tmpOpacity;
      });
    });
  }

  @override
  void dispose() {
    animationTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: opacityRedLight,
          child: Image.asset(assetPathRedLight),
        ),
        Opacity(
          opacity: opacityGreenLight,
          child: Image.asset(assetPathGreenLight),
        ),
      ],
    );
  }
}
