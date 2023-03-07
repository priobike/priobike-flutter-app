import 'dart:math';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/traffic/services/traffic_service.dart';

class TrafficChart extends StatefulWidget {
  const TrafficChart({Key? key}) : super(key: key);
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

    return Expanded(
      child: Column(
        children: [
          Container(
            height: height,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.black.withOpacity(0.07),
              ),
              color: isNow ? null : const Color.fromARGB(255, 225, 225, 225),
              gradient: isNow
                  ? LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    )
                  : null,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
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
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 4, right: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Content(
                text: "Verkehr",
                context: context,
              ),
              Content(
                text: trafficService.trafficStatus!,
                context: context,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
