import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/routing/models/waypoint.dart';

/// Widget for last search results
class SelectOnMapButton extends StatelessWidget {
  final Function onPressed;
  const SelectOnMapButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    return Column(mainAxisAlignment: MainAxisAlignment.start, children: [
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onPressed(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child:
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Icon(Icons.map),
            Content(text: "Auf Karte auswählen", context: context),
          ]),
        ),
      ),
      Container(
        width: frame.size.width,
        height: 10,
        color: Theme.of(context).colorScheme.surface,
      ),
    ]);

    // return Column(mainAxisAlignment: MainAxisAlignment.start, children: [
    //   Padding(
    //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
    //     child:
    //         Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    //       const Icon(Icons.map),
    //       Content(text: "Auf Karte auswählen", context: context),
    //       TextButton(
    //         style: TextButton.styleFrom(
    //           shape: RoundedRectangleBorder(
    //             side: const BorderSide(
    //                 color: Colors.grey, width: 1, style: BorderStyle.solid),
    //             borderRadius: BorderRadius.circular(50),
    //           ),
    //         ),
    //         onPressed: () => onPressed(),
    //         child: Content(text: "Karte", context: context),
    //       ),
    //     ]),
    //   ),
    //   Container(
    //     width: frame.size.width,
    //     height: 10,
    //     color: Theme.of(context).colorScheme.surface,
    //   ),
    // ]);
  }
}
