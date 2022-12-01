import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';

/// The current location button.
class CurrentLocationButton extends StatelessWidget {
  final Function onPressed;

  const CurrentLocationButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    return Column(mainAxisAlignment: MainAxisAlignment.start, children: [
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onPressed(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Icon(Icons.gps_fixed_outlined),
            Content(text: "Aktueller Standort", context: context),
          ]),
        ),
      ),
      Container(
        width: frame.size.width,
        height: 10,
        color: Theme.of(context).colorScheme.surface,
      ),
    ]);
  }
}
