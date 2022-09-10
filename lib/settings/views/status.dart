import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';

class SGStatusView extends StatefulWidget {
  const SGStatusView({Key? key}) : super(key: key);

  @override 
  SGStatusViewState createState() => SGStatusViewState();
}

class SGStatusViewState extends State<SGStatusView> {
  /// A map controller for the map.
  MapboxMapController? mapController;

  /// A callback which is executed when the map was created.
  Future<void> onMapCreated(MapboxMapController controller) async {
    mapController = controller;

    mapController?.updateContentInsets(EdgeInsets.only(
      top: 0,
      bottom: 142 + MediaQuery.of(context).padding.bottom,
      left: 0,
      right: 0,
    ));
  }

  /// A callback which is executed when the map style was loaded.
  Future<void> onStyleLoaded(BuildContext context) async {
    if (mapController == null) return;

    final settings = Provider.of<SettingsService>(context, listen: false);
    final baseUrl = settings.backend.path;
    final url = "https://$baseUrl/prediction-monitor-nginx/predictions.geojson";

    await mapController?.addSource(
      "signal-groups",
      GeojsonSourceProperties(data: url),
    );

    await mapController?.addLayer(
      "signal-groups",
      "signal-group-circles-bg",
      const CircleLayerProperties(
        circleColor: "#000000", 
        circleRadius: 5,
      ),
    );

    await mapController?.addLayer(
      "signal-groups",
      "signal-group-circles",
      const CircleLayerProperties(
        circleColor: [
          "interpolate",
          ["linear"],
          ["number", ["get", "prediction_quality"]],
          -1, "#000000",
          0, "#ff0000",
          0.5, "#ffff00",
          1, "#00ff00",
        ], 
        circleRadius: 3
      ),
    );

    // Add a text layer for the signal group ids.
    await mapController?.addLayer(
      "signal-groups",
      "signal-group-ids",
      SymbolLayerProperties(
        textField: ["get", "prediction_sg_id"],
        textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
        textSize: 16,
        textOffset: [
          Expressions.literal,
          [0, 1]
        ],
        textColor: Theme.of(context).colorScheme.brightness == Brightness.dark
          ? "#ffffff"
          : "#000000",
        // Hide after zoom level 15.
        textOpacity: [
          "interpolate",
          ["linear"],
          ["zoom"],
          0, 0,
          14, 0,
          15, 1,
        ],
        textAllowOverlap: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Stack(children: [
      AppMap(
        dragEnabled: true,
        onMapCreated: onMapCreated, 
        onStyleLoaded: () => onStyleLoaded(context),
      ),
      SafeArea(
        minimum: const EdgeInsets.only(top: 64),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppBackButton(icon: Icons.chevron_left_rounded, onPressed: () => Navigator.pop(context)),
        ]),
      ),
      // A small info window.
      SafeArea(child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(height: 128, child: Tile(
            fill: Colors.white,
            content: Column(children: [
              Row(children: [
                Container(
                  height: 16,
                  width: 16,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const HSpace(),
                Text("-1 Prognosequalität", style: Theme.of(context).textTheme.bodyText2),
              ]),
              const SmallVSpace(),
              Row(children: [
                Container(
                  height: 16,
                  width: 16,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 0, 0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const HSpace(),
                Text("0% Prognosequalität", style: Theme.of(context).textTheme.bodyText2),
              ]),
              const SmallVSpace(),
              Row(children: [
                Container(
                  height: 16,
                  width: 16,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const HSpace(),
                Text("50% Prognosequalität", style: Theme.of(context).textTheme.bodyText2),
              ]),
              const SmallVSpace(),
              Row(children: [
                Container(
                  height: 16,
                  width: 16,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 0, 255, 0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const HSpace(),
                Text("100% Prognosequalität", style: Theme.of(context).textTheme.bodyText2),
              ]),
            ])
          )),
        ),
      )),
    ]));
  }
}