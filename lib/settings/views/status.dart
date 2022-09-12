import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';

class SGStatusViewLegendElement {
  final String title;
  final Color color;

  SGStatusViewLegendElement(this.title, this.color);
}

class SGStatusViewMode {
  /// The name of the mode.
  final String name;

  /// The MapBox color function.
  final dynamic color;

  /// The MapBox first label function.
  final dynamic firstLabel;

  /// The MapBox second label function.
  final dynamic secondLabel;

  /// The legend.
  final List<SGStatusViewLegendElement> legend;

  const SGStatusViewMode({
    required this.name,
    required this.color,
    required this.firstLabel,
    required this.secondLabel,
    required this.legend,
  });

  static final all = [
    SGStatusViewMode(
      name: "Prognosequalität",
      color: [
        "interpolate", ["linear"],
        ["number", ["get", "prediction_quality"]],
        -1, "#000000",
        0, "#ff0000",
        0.5, "#ffff00",
        1, "#00ff00",
      ],
      firstLabel: [
        "concat",
        ["get", "thing_name"],
        " ",
        ["get", "thing_properties_lanetype"],
      ],
      secondLabel: ["get", "prediction_quality"],
      legend: [
        SGStatusViewLegendElement("Keine Prognose", const Color(0xff000000)),
        SGStatusViewLegendElement("Schlechte Prognose", const Color(0xffff0000)),
        SGStatusViewLegendElement("Mittlere Prognose", const Color(0xffffff00)),
        SGStatusViewLegendElement("Gute Prognose", const Color(0xff00ff00)),
      ],
    ),
    SGStatusViewMode(
      name: "Zeit seit letzter Prognose",
      color: [
        "case",
          // Display black if prediction_available is false.
          [
            "==", ["get", "prediction_available"], false
          ],
          "#000000",
          // Otherwise, display a color based on the time since the last prediction.
          [
            "interpolate", ["linear"],
            ["number", ["get", "prediction_time_diff"]],
            0, "#00ff00",
            60, "#00ff00",
            600, "#ffff00",
            3600, "#ff0000",
          ]
      ],
      firstLabel: [
        "concat",
        ["get", "thing_name"],
        " ",
        ["get", "thing_properties_lanetype"],
      ],
      // Convert prediction_time_diff from unix millis to minutes.
      // But display nothing if prediction_available = false
      secondLabel: [
        "case",
          [
            "==", ["get", "prediction_available"], false
          ],
          "Keine Prognose",
          [
            "concat",
            ["to-string", ["floor", [
              "/", ["number", ["get", "prediction_time_diff"]], 60
            ]]],
            " min",
          ]
      ],
      legend: [
        SGStatusViewLegendElement("Keine Prognose", const Color(0xff000000)),
        SGStatusViewLegendElement("Letzte Prognose vor >1h", const Color(0xffff0000)),
        SGStatusViewLegendElement("Letzte Prognose vor 10min", const Color(0xffffff00)),
        SGStatusViewLegendElement("Letzte Prognose vor 1min", const Color(0xff00ff00)),
      ],
    ),
  ];
}

class SGStatusView extends StatefulWidget {
  const SGStatusView({Key? key}) : super(key: key);

  @override 
  SGStatusViewState createState() => SGStatusViewState();
}

class SGStatusViewState extends State<SGStatusView> {
  /// A map controller for the map.
  MapboxMapController? mapController;

  /// The current mode.
  SGStatusViewMode mode = SGStatusViewMode.all.first;

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

  /// A callback that is executed when the mode was changed.
  Future<void> updateMapMode(SGStatusViewMode mode) async {
    await mapController?.removeLayer("sg-lines-bg");
    await mapController?.addLayer("sg-lanes", "sg-lines-bg", const LineLayerProperties(
      lineColor: "#000000", 
      lineCap: "round",
      lineJoin: "round",
      lineWidth: 4
    ));

    await mapController?.removeLayer("sg-lines");
    await mapController?.addLayer("sg-lanes", "sg-lines", LineLayerProperties(
      lineColor: mode.color, 
      lineCap: "round",
      lineJoin: "round",
      lineWidth: 2
    ));

    await mapController?.removeLayer("sg-circles");
    await mapController?.addLayer("sg-locs", "sg-circles", CircleLayerProperties(
      circleColor: mode.color, 
      circleRadius: 3,
      circleStrokeWidth: 2,
      circleStrokeColor: "#000000",
    ));

    await mapController?.removeLayer("sg-first-labels");
    await mapController?.addLayer("sg-locs", "sg-first-labels", SymbolLayerProperties(
      textField: mode.firstLabel,
      textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
      textSize: 14,
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
        15, 0.75,
      ],
      textAllowOverlap: true,
    ));

    await mapController?.removeLayer("sg-second-labels");
    await mapController?.addLayer("sg-locs", "sg-second-labels", SymbolLayerProperties(
      textField: mode.secondLabel,
      textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
      textSize: 12,
      textOffset: [
        Expressions.literal,
        [0, 2]
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
        15, 0.75,
      ],
      textAllowOverlap: true,
    ));
  }

  /// A callback which is executed when the map style was loaded.
  Future<void> onStyleLoaded(BuildContext context) async {
    if (mapController == null) return;

    final settings = Provider.of<SettingsService>(context, listen: false);
    final baseUrl = settings.backend.path;

    await mapController?.addSource("sg-locs", GeojsonSourceProperties(
      data: "https://$baseUrl/prediction-monitor-nginx/predictions-locations.geojson"
    ));

    await mapController?.addSource("sg-lanes", GeojsonSourceProperties(
      data: "https://$baseUrl/prediction-monitor-nginx/predictions-lanes.geojson"
    ));

    updateMapMode(mode);
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
      SafeArea(child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Tile(
            fill: Colors.white,
            content: SizedBox(height: 80, child: PageView.builder(
              itemCount: SGStatusViewMode.all.length,
              onPageChanged: (index) {
                setState(() {
                  mode = SGStatusViewMode.all[index];
                });
                updateMapMode(mode);
              },
              itemBuilder: (context, index) {
                final mode = SGStatusViewMode.all[index];
                return Column(children: mode.legend.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    Container(
                      height: 16,
                      width: 16,
                      decoration: BoxDecoration(
                        color: e.color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const HSpace(),
                    Small(text: e.title, context: context, color: Colors.black),
                  ]),
                )).toList());
              },
            )), 
          ),
        ),
      )),     
    ]));
  }
}