import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:priobike/ride/views/button.dart';
import 'package:provider/provider.dart';

class RideTrafficLightView extends StatefulWidget {
  const RideTrafficLightView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RideTrafficLightViewState();
}

class RideTrafficLightViewState extends State<RideTrafficLightView> {
  /// The associated ride service, which is injected by the provider.
  late Ride rs;

  @override
  void didChangeDependencies() {
    rs = Provider.of<Ride>(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final alternativeView = Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.05),
        borderRadius: BorderRadius.circular(64),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: const CancelButton(
        borderRadius: 128,
        text: "Beenden",
      ),
    );

    // Don't show a countdown if...
    if (rs.currentRecommendation == null || // we have no recommendation
            rs.currentRecommendation!.sg == null || // if no signal group is focused
            rs.currentRecommendation!.error // or if there is an error
        ) return alternativeView;

    // Check if we have all auxiliary data that the app calculated.
    if (rs.calcCurrentSignalIsGreen == null || rs.calcCurrentPhaseChangeTime == null) return alternativeView;
    // Calculate the countdown.
    final countdown = rs.calcCurrentPhaseChangeTime!.difference(DateTime.now()).inSeconds;
    // If the countdown is 0 (or negative), we hide the countdown. In this way the user
    // is not confused if the countdown is at 0 for a few seconds.
    final countdownLabel = countdown > 0 ? "$countdown" : "";

    final trafficLight = Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(
        // Don't use the CI green here.
        color: rs.calcCurrentSignalIsGreen! ? const Color.fromARGB(255, 0, 255, 106) : CI.red,
        borderRadius: BorderRadius.circular(64),
        border: Border.all(color: const Color.fromARGB(255, 0, 0, 0), width: 2),
      ),
      child: Center(
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Transform.translate(
                child: Text(
                  countdownLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 4
                      ..color = const Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
                offset: const Offset(0, -24)),
            Transform.translate(
                child: Text(
                  countdownLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                offset: const Offset(0, -24)),
            Transform.translate(child: const CancelButton(), offset: const Offset(0, 24)),
          ],
        ),
      ),
    );

    final showCountdown = rs.currentRecommendation!.distance < 500 && (rs.currentRecommendation!.quality ?? 0) > 0.9;

    return AnimatedCrossFade(
      firstCurve: Curves.easeInOutCubic,
      secondCurve: Curves.easeInOutCubic,
      sizeCurve: Curves.easeInOutCubic,
      duration: const Duration(milliseconds: 500),
      firstChild: trafficLight,
      secondChild: alternativeView,
      crossFadeState: showCountdown ? CrossFadeState.showFirst : CrossFadeState.showSecond,
    );
  }
}
