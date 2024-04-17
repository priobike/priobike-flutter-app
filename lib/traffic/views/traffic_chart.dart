import 'dart:math';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/traffic/services/traffic_service.dart';

class TrafficChart extends StatefulWidget {
  const TrafficChart({super.key});

  @override
  TrafficChartState createState() => TrafficChartState();
}

class TrafficChartState extends State<TrafficChart> {
  /// Backend service for traffic prediction.
  late Traffic trafficService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();
    trafficService = getIt<Traffic>();
    trafficService.addListener(update);
    trafficService.fetch();
  }

  @override
  void dispose() {
    trafficService.removeListener(update);
    super.dispose();
  }

  /// Element for Bar Chart for Traffic Prediction. The Bar for the current time is highlighted.
  Widget renderTrafficBar(int hour) {
    final trafficFlow = trafficService.trafficData![hour];
    if (trafficFlow == null) return Container();

    final isNow = (hour == DateTime.now().hour);
    final availableHeight = (MediaQuery.of(context).size.height) / 6;
    // Calculate the height of the bar, but make sure that its not too small or too big.
    final scaledTrafficFlow = min(1, max(0, ((trafficFlow - 0.94) / (0.05))));
    // Invert the value, so that more traffic flow = less congestion.
    final height = availableHeight * (1 - scaledTrafficFlow);

    // A wrapper that adds a shimmering animation to the bar, if it is the current time.
    Widget Function(Widget) wrapper = (widget) => widget;
    if (isNow && trafficService.scoreNow != null) {
      // Show the current score in a shimmering animation.
      final scaledTrafficFlowNow = min(1, max(0, (((trafficService.scoreNow!) - 0.94) / (0.05))));
      final nowHeight = availableHeight * (1 - scaledTrafficFlowNow);
      final color = trafficService.trafficColor ?? CI.radkulturRed;
      wrapper = (widget) => Stack(
            alignment: Alignment.bottomCenter,
            children: nowHeight > height
                ? [
                    Container(
                      margin: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                          bottomLeft: Radius.circular(4),
                        ),
                      ),
                      height: nowHeight,
                    ),
                    widget,
                  ]
                : [
                    widget,
                    Container(
                      margin: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                          bottomLeft: Radius.circular(4),
                        ),
                      ),
                      height: nowHeight,
                    ),
                  ],
          );
    }

    return Expanded(
      child: Column(
        children: [
          wrapper(
            Container(
              height: height,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color.fromARGB(255, 205, 205, 205)
                    : const Color.fromARGB(255, 77, 77, 77),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Small(
            text: "$hour:00",
            context: context,
          )
        ],
      ),
    );
  }

  /// Render the Traffic Prediction Bar Chart.
  @override
  Widget build(BuildContext context) {
    if (trafficService.hasLoaded == false) return Container();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).colorScheme.onTertiary.withOpacity(0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BoldContent(
                text: trafficService.trafficClass!,
                context: context,
              ),
              Flexible(
                child: Content(
                  text: trafficService.trafficDifference!,
                  context: context,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int hour in trafficService.trafficData!.keys)
                if (trafficService.trafficData![hour] != null) renderTrafficBar(hour)
            ],
          ),
        ],
      ),
    );
  }
}
