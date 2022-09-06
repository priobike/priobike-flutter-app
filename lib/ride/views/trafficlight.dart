

import 'package:flutter/material.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:provider/provider.dart';

class RideTrafficLightView extends StatefulWidget {
  const RideTrafficLightView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RideTrafficLightViewState();
}

class RideTrafficLightViewState extends State<RideTrafficLightView> {
  /// The associated ride service, which is injected by the provider.
  late RideService rs;

  @override
  void didChangeDependencies() {
    rs = Provider.of<RideService>(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (rs.currentRecommendation == null) return Container();
    if (rs.currentRecommendation!.distance > 100) return Container();
    return Container(
      width: 128, height: 128,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          stops: const [0.25, 1.0],
          colors: rs.currentRecommendation!.isGreen 
            ? const [Color.fromARGB(255, 0, 255, 0), Color.fromARGB(255, 0, 128, 0)]
            : const [Color.fromARGB(255, 255, 0, 0), Color.fromARGB(255, 140, 0, 0)],
        ),
        borderRadius: BorderRadius.circular(64),
        border: Border.all(color: const Color.fromARGB(255, 0, 0, 0), width: 2),
      ),
      child: Center(child: Stack(children: [
        Text(
          "${rs.currentRecommendation!.countdown}",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..color = Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        Text(
          "${rs.currentRecommendation!.countdown}",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
      ])),
    );
  }
}