import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/prediction.dart';
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
  mapbox.MapboxMap? mapController;

  /// A callback which is executed when the map was created.
  Future<void> onMapCreated(mapbox.MapboxMap controller) async {
    mapController = controller;
  }

  /// A callback which is executed when the map style was loaded.
  Future<void> onStyleLoaded(mapbox.StyleLoadedEventData styleLoadedEventData) async {
    if (mapController == null) return;

    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;
    final statusProviderSubPath = settings.predictionMode.statusProviderSubPath;

    await mapController?.style.styleSourceExists("sg-locs").then((exists) async {
      if (!exists) {
        await mapController?.style.addSource(
          mapbox.GeoJsonSource(
              id: "sg-locs", data: "https://$baseUrl/$statusProviderSubPath/predictions-locations.geojson"),
        );
      }
    });

    await mapController?.style.styleSourceExists("sg-lanes").then((exists) async {
      if (!exists) {
        await mapController?.style.addSource(
          mapbox.GeoJsonSource(
              id: "sg-lanes", data: "https://$baseUrl/$statusProviderSubPath/predictions-lanes.geojson"),
        );
      }
    });

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

    await mapController?.style.styleLayerExists("sg-lines-bg").then((exists) async {
      if (!exists) {
        await mapController?.style.addLayer(
          mapbox.LineLayer(
            sourceId: "sg-lanes",
            id: "sg-lines-bg",
            lineColor: Colors.black.value,
            lineCap: mapbox.LineCap.ROUND,
            lineJoin: mapbox.LineJoin.ROUND,
            lineWidth: 4,
          ),
        );
      }
    });

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

    await mapController?.style.styleLayerExists("sg-lines").then((exists) async {
      if (!exists) {
        await mapController?.style.addLayer(
          mapbox.LineLayer(
            sourceId: "sg-lanes",
            id: "sg-lines",
            lineCap: mapbox.LineCap.ROUND,
            lineJoin: mapbox.LineJoin.ROUND,
            lineWidth: 2,
          ),
        );

        await mapController?.style.setStyleLayerProperty('sg-lines', 'line-color', jsonEncode(color));
      }
    });

    await mapController?.style.styleLayerExists("sg-circles").then((exists) async {
      if (!exists) {
        await mapController?.style.addLayer(
          mapbox.CircleLayer(
            sourceId: "sg-locs",
            id: "sg-circles",
            circleColor: Colors.white.value,
            circleRadius: 3,
            circleStrokeWidth: 2,
            circleStrokeColor: Colors.black.value,
          ),
        );

        await mapController?.style.setStyleLayerProperty('sg-circles', 'circle-color', jsonEncode(color));
      }
    });

    await mapController?.style.styleLayerExists("sg-first-labels").then((exists) async {
      if (!exists) {
        await mapController?.style.addLayer(
          mapbox.SymbolLayer(
            sourceId: "sg-locs",
            id: "sg-first-labels",
            textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
            textSize: 14,
            textColor:
                Theme.of(context).colorScheme.brightness == Brightness.dark ? Colors.white.value : Colors.black.value,
            textAllowOverlap: true,
          ),
        );

        await mapController?.style.setStyleLayerProperty(
            'sg-first-labels',
            'text-offset',
            jsonEncode([
              "literal",
              [0, 1]
            ]));
        await mapController?.style.setStyleLayerProperty('sg-first-labels', 'text-field', jsonEncode(title));
        await mapController?.style.setStyleLayerProperty(
            'sg-first-labels',
            'text-opacity',
            jsonEncode(
              [
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
            ));
      }
    });

    await mapController?.style.styleLayerExists("sg-second-labels").then((exists) async {
      if (!exists) {
        await mapController?.style.addLayer(
          mapbox.SymbolLayer(
            sourceId: "sg-locs",
            id: "sg-second-labels",
            textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
            textSize: 12,
            textColor:
                Theme.of(context).colorScheme.brightness == Brightness.dark ? Colors.white.value : Colors.black.value,
            textAllowOverlap: true,
          ),
        );

        await mapController?.style.setStyleLayerProperty(
            'sg-second-labels',
            'text-offset',
            jsonEncode([
              "literal",
              [0, 2.5]
            ]));
        await mapController?.style.setStyleLayerProperty('sg-second-labels', 'text-field', jsonEncode(subtitle));
        await mapController?.style.setStyleLayerProperty(
            'sg-second-labels',
            'text-opacity',
            jsonEncode(
              [
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
            ));
      }
    });
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
        body: Stack(
          children: [
            AppMap(
              // Logo is on the button left, attribution is on the button right.
              logoViewMargins: Point(50, 350 + MediaQuery.of(context).padding.bottom),
              attributionButtonMargins: Point(50, 350 + MediaQuery.of(context).padding.bottom),
              onMapCreated: onMapCreated,
              onStyleLoaded: onStyleLoaded,
            ),
            SafeArea(
              minimum: const EdgeInsets.only(top: 8),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppBackButton(icon: Icons.chevron_left_rounded, onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 12,
                    bottom: 12,
                    right: 12,
                  ),
                  child: Tile(
                    fill: Theme.of(context).colorScheme.background,
                    content: SizedBox(
                      height: 60,
                      child: Column(
                        children: legend
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
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
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
