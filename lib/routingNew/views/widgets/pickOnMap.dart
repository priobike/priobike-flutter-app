import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/routingNew/views/widgets/selectOnMap.dart';

/// Widget for last search results
class PickOnMap extends StatelessWidget {
  const PickOnMap({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    return Column(mainAxisAlignment: MainAxisAlignment.start, children: [
      Container(
        width: frame.size.width,
        height: 10,
        color: Theme.of(context).colorScheme.surface,
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Icon(Icons.map),
          Content(text: "Auf Karte auswählen", context: context),
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                side: const BorderSide(
                    color: Colors.grey, width: 1, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SelectOnMapView(),
                ),
              );
            },
            child: Content(text: "Karte", context: context),
          ),
        ]),
      ),
    ]);
  }
}
