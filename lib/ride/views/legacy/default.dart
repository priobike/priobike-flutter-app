import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:priobike/ride/views/button.dart';
import 'package:priobike/ride/views/legacy/arrow.dart';
import 'package:provider/provider.dart';


class DefaultCyclingView extends StatefulWidget {
  const DefaultCyclingView({Key? key}) : super(key: key);

  static double interpolate(double min, double max, double t) {
    final double lerp = (t - min) / (max - min);
    return lerp;
  }

  @override
  State<DefaultCyclingView> createState() => _DefaultCyclingViewState();
}

class _DefaultCyclingViewState extends State<DefaultCyclingView> {
  late Ride ride;

  final int sliderThumbWidth = 20;
  final double maxSpeedDiff = 10.0;

  @override
  Widget build(BuildContext context) {
    ride = Provider.of<Ride>(context);

    if (ride.currentRecommendation == null) return Container();
    final recommendation = ride.currentRecommendation!;

    num percent = DefaultCyclingView.interpolate(
      maxSpeedDiff,
      -maxSpeedDiff,
      recommendation.speedDiff.clamp(-maxSpeedDiff, maxSpeedDiff),
    );

    return Scaffold(
      body: SafeArea(child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SmallVSpace(),
          BoldSmall(text: recommendation.error
                ? "Fehler: ${recommendation.errorMessage}"
                : '', context: context),
          Row(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0.0, 8.0, 8.0, 8.0),
              child: NavigationArrow(
                sign: recommendation.navSign,
                width: 70,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${recommendation.navDist.toStringAsFixed(0)} m",
                  style: const TextStyle(
                    fontSize: 40,
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 100,
                  child: Text(
                    recommendation.navText ?? "",
                    style: const TextStyle(fontSize: 16),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ]),
          const Spacer(),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(children: [
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.width / 3,
                    width: MediaQuery.of(context).size.width / 3,
                    child: CircularProgressIndicator(
                      strokeWidth: 30,
                      backgroundColor: Colors.black26,
                      color: recommendation.isGreen
                          ? const Color.fromARGB(255, 54, 222, 70)
                          : Colors.red,
                      value: recommendation.countdown / 60,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      "${recommendation.countdown}s ",
                      style: const TextStyle(fontSize: 50),
                    ),
                  ),
                ),
              ]),
              const SmallHSpace(),
              Expanded(
                  child: Header(text:
                "Ampel in ${recommendation.distance.toStringAsFixed(0)}m", fontSize: 28, context: context
              ))
            ],
          )),
          const Spacer(),
          Stack(
            children: [
              Container(
                height: 100,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.red,
                      Colors.black,
                      Color.fromARGB(255, 54, 222, 70),
                      Colors.black,
                      Colors.red,
                    ],
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Transform.translate(
                    offset: Offset(
                      percent * constraints.maxWidth - sliderThumbWidth / 2,
                      0,
                    ),
                    child: Container(
                      height: 100,
                      width: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color.fromARGB(255, 54, 54, 54),
                          width: 2,
                        ),
                      ),
                    )
                  );
                },
              ),
            ],
          ),
          const SmallVSpace(),
          Header(
            text: "${recommendation.speedDiff > 0 ? "+" : ""}${(recommendation.speedDiff * 3.6).toStringAsFixed(0)} km/h",
            context: context,
          ),
          if (recommendation.speedDiff > 0)
            SubHeader(text: "Schneller!", context: context),
          if (recommendation.speedDiff < 0)
            SubHeader(text: "Langsamer!", context: context),
          if (recommendation.speedDiff == 0)
            SubHeader(text: "Geschwindigkeit halten.", context: context),

          const SizedBox(
            width: double.infinity,
            child: CancelButton(text: "Fahrt beenden"),
          ),
        ],
      )),
    );
  }
}
