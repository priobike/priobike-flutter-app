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
  late TrafficService trafficService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();
    trafficService = getIt<TrafficService>();
    trafficService.addListener(update);
    trafficService.fetch();
  }

  @override
  void dispose() {
    trafficService.removeListener(update);
    trafficService.reset();
    super.dispose();
  }

  /// Element for Bar Chart for Traffic Prediction. The Bar for the current time is highlighted.
  Widget renderTrafficBar(double height, int time, bool highlightHourNow) {
    final availableWidth = (MediaQuery.of(context).size.width - 24);
    return Column(
      children: [
        Container(
          // max. 7 bars + 5 padding on each side
          width: availableWidth / 7 - 10,
          height: height,
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: !highlightHourNow
                  ? [
                      const Color.fromARGB(255, 166, 168, 168),
                      const Color.fromARGB(255, 214, 215, 216),
                    ]
                  : [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
            ),
            shape: BoxShape.rectangle,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(5),
              topRight: Radius.circular(5),
            ),
          ),
        ),
        Small(
          text: "$time:00",
          context: context,
        )
      ],
    );
  }

  /// Render the Traffic Prediction Bar Chart.
  @override
  Widget build(BuildContext context) {
    if (trafficService.hasLoaded == false) return Container();
    final availableHeight = (MediaQuery.of(context).size.height) / 6;
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 4, right: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Content(
                text: "Verkehrslage",
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
              for (int key in trafficService.trafficData!.keys)
                if (trafficService.trafficData![key] != null)
                  renderTrafficBar(
                      ((trafficService.trafficData![key]! - trafficService.lowestValue! * 0.99) /
                              (trafficService.highestValue! * 1.01 - trafficService.lowestValue! * 0.99)) *
                          availableHeight,
                      key,
                      (key == DateTime.now().hour))
            ],
          ),
        ],
      ),
    );
  }
}
