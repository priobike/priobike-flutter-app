import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';

class SGStatusMapViewLegendElement {
  final String title;
  final Color color;

  SGStatusMapViewLegendElement(this.title, this.color);
}

class SGStatusMapView extends StatefulWidget {
  const SGStatusMapView({Key? key}) : super(key: key);

  @override
  SGStatusMapViewState createState() => SGStatusMapViewState();
}

class SGStatusMapViewState extends State<SGStatusMapView> {
  /// A map controller for the map.
  MapboxMapController? mapController;

  /// Bool to save if sources have been initialized.
  bool sourcesInitialized = false;

  /// A callback which is executed when the map was created.
  Future<void> onMapCreated(MapboxMapController controller) async {
    mapController = controller;

    mapController?.updateContentInsets(EdgeInsets.only(
      top: 0,
      bottom: 108 + MediaQuery.of(context).padding.bottom,
      left: 18,
      right: 18,
    ));
  }

  /// A callback which is executed when the map style was loaded.
  Future<void> onStyleLoaded(BuildContext context) async {
    if (mapController == null) return;

    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;

    if (!sourcesInitialized) {
      await mapController?.addSource(
        "sg-locs",
        GeojsonSourceProperties(data: "https://$baseUrl/prediction-monitor-nginx/predictions-locations.geojson"),
      );
      await mapController?.addSource(
        "sg-lanes",
        GeojsonSourceProperties(data: "https://$baseUrl/prediction-monitor-nginx/predictions-lanes.geojson"),
      );
      sourcesInitialized = true;
    }

    // Define the color scheme for the layers.
    final color = [
      "case",
      // Display black if prediction_available is false.
      [
        "==",
        ["get", "prediction_available"],
        false
      ],
      "#000000",
      // Otherwise, display a color based on the time since the last prediction.
      [
        "interpolate",
        ["linear"],
        [
          "number",
          ["get", "prediction_time_diff"]
        ],
        // If the prediction is recent, interpolate based on the prediction quality.
        60,
        [
          "interpolate",
          ["linear"],
          [
            "number",
            ["get", "prediction_quality"]
          ],
          -1,
          "#000000",
          0,
          "rgb(230, 51, 40)",
          1,
          "rgb(0, 115, 255)",
        ],
        // Otherwise, show that the prediction is bad.
        600,
        "rgb(230, 51, 40)",
      ]
    ];

    // Define the label that will be displayed on top.
    final title = [
      "concat",
      ["get", "thing_name"],
      " ",
      ["get", "thing_properties_lanetype"],
    ];

    await mapController?.removeLayer("sg-lines-bg");
    await mapController?.addLayer(
      "sg-lanes",
      "sg-lines-bg",
      const LineLayerProperties(
        lineColor: "#000000",
        lineCap: "round",
        lineJoin: "round",
        lineWidth: 4,
      ),
    );

    // Define the label that will be displayed below.
    final subtitle = [
      "case",
      [
        "==",
        ["get", "prediction_available"],
        false
      ],
      "Keine Prognose",
      [
        "concat",
        [
          "concat",
          [
            "to-string",
            [
              "floor",
              [
                "/",
                [
                  "number",
                  ["get", "prediction_time_diff"]
                ],
                60
              ]
            ]
          ],
          " min - Qualität:",
        ],
        ["get", "prediction_quality"],
      ]
    ];

    await mapController?.removeLayer("sg-lines");
    await mapController?.addLayer(
      "sg-lanes",
      "sg-lines",
      LineLayerProperties(
        lineColor: color,
        lineCap: "round",
        lineJoin: "round",
        lineWidth: 2,
      ),
    );

    await mapController?.removeLayer("sg-circles");
    await mapController?.addLayer(
      "sg-locs",
      "sg-circles",
      CircleLayerProperties(
        circleColor: color,
        circleRadius: 3,
        circleStrokeWidth: 2,
        circleStrokeColor: "#000000",
      ),
    );

    await mapController?.removeLayer("sg-first-labels");
    await mapController?.addLayer(
      "sg-locs",
      "sg-first-labels",
      SymbolLayerProperties(
        textField: title,
        textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
        textSize: 14,
        textOffset: [
          Expressions.literal,
          [0, 1]
        ],
        textColor: Theme.of(context).colorScheme.brightness == Brightness.dark ? "#ffffff" : "#000000",
        // Hide after zoom level 15.
        textOpacity: [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          0,
          16,
          0,
          17,
          0.75,
        ],
        textAllowOverlap: true,
      ),
    );

    await mapController?.removeLayer("sg-second-labels");
    await mapController?.addLayer(
      "sg-locs",
      "sg-second-labels",
      SymbolLayerProperties(
        textField: subtitle,
        textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
        textSize: 12,
        textOffset: [
          Expressions.literal,
          [0, 2.5]
        ],
        textColor: Theme.of(context).colorScheme.brightness == Brightness.dark ? "#ffffff" : "#000000",
        // Hide after zoom level 15.
        textOpacity: [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          0,
          16,
          0,
          17,
          0.75,
        ],
        textAllowOverlap: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final legend = [
      SGStatusMapViewLegendElement("Keine Prognose", const Color(0xff000000)),
      SGStatusMapViewLegendElement("Schlechte oder veraltete Prognose", CI.red),
      SGStatusMapViewLegendElement("Aktuelle und gute Prognose", CI.blue),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
          body: Stack(children: [
        AppMap(
          dragEnabled: true,
          onMapCreated: onMapCreated,
          onStyleLoaded: () => onStyleLoaded(context),
        ),
        SafeArea(
          minimum: const EdgeInsets.only(top: 8),
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppBackButton(icon: Icons.chevron_left_rounded, onPressed: () => Navigator.pop(context)),
            ]),
          ),
        ),
        SafeArea(
            child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Tile(
              fill: Theme.of(context).colorScheme.background,
              content: SizedBox(
                height: 60,
                child: Column(
                  children: legend
                      .map((e) => Padding(
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
                              Small(text: e.title, context: context),
                            ]),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        )),
      ])),
    );
  }
}
