import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/routing.dart';

class SpeedometerAlert extends StatelessWidget {
  /// The size of the speedometer.
  final Size size;

  const SpeedometerAlert({Key? key, required this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width * 0.65,
      height: size.width * 0.65,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.center,
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: CI.orange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(1),
                    blurRadius: 5,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              padding: const EdgeInsets.only(bottom: 2),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const VSpace(),
            if (getIt<Routing>().waypointsOutOfBoundaries)
              BoldContent(
                textAlign: TextAlign.center,
                text: "Du befindest dich jetzt außerhalb der Stadtgrenze\n",
                color: Colors.white,
                context: context,
              ),
            if (getIt<Routing>().waypointsOutOfBoundaries)
              Content(
                textAlign: TextAlign.center,
                text: "Dir wird wieder eine Route berechnet, sobald du wieder in der Stadt bist.",
                color: Colors.white,
                context: context,
              ),
            if (!getIt<Routing>().waypointsOutOfBoundaries)
              BoldContent(
                textAlign: TextAlign.center,
                text: "Fehler bei der Berechnung einer neuen Route.",
                color: Colors.white,
                context: context,
              ),
          ],
        ),
      ),
    );
  }
}
