import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:priobike/common/layout/annotated_region.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/http.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

class SGStatusMapViewLegendElement {
  final String title;
  final Color color;

  SGStatusMapViewLegendElement(this.title, this.color);
}

class SGStatusMapView extends StatefulWidget {
  const SGStatusMapView({super.key});

  @override
  SGStatusMapViewState createState() => SGStatusMapViewState();
}

class SGStatusMapViewState extends State<SGStatusMapView> {
  /// A map controller for the map.
  mapbox.MapboxMap? mapController;

  late Settings settings;

  /// A controller for the search text field.
  final searchController = TextEditingController();

  /// The sg-locs geojson.
  var sgLocs = {};

  /// The sg-lanes geojson.
  var sgLanes = {};

  /// A callback which is executed when the map was created.
  Future<void> onMapCreated(mapbox.MapboxMap controller) async {
    mapController = controller;
  }

  @override
  void initState() {
    super.initState();
    settings = getIt<Settings>();
  }

  /// A callback which is executed when the map style was loaded.
  Future<void> onStyleLoaded(mapbox.StyleLoadedEventData styleLoadedEventData) async {
    if (mapController == null) return;

    final textColor =
        Theme.of(context).colorScheme.brightness == Brightness.dark ? Colors.white.value : Colors.black.value;

    final baseUrl = settings.backend.path;

    final sourceLocsExists = await mapController?.style.styleSourceExists("sg-locs");
    if (sourceLocsExists != null && !sourceLocsExists) {
      // Fetch the geojson from the server.
      final url = Uri.parse("https://$baseUrl/prediction-monitor-nginx/predictions-locations.geojson");
      final response = await Http.get(url);
      if (response.statusCode != 200) return;
      sgLocs = jsonDecode(response.body);
      await mapController?.style.addSource(
        mapbox.GeoJsonSource(id: "sg-locs", data: json.encode(sgLocs)),
      );
    }

    final sourceSGLanesExists = await mapController?.style.styleSourceExists("sg-lanes");
    if (sourceSGLanesExists != null && !sourceSGLanesExists) {
      // Fetch the geojson from the server.
      final url = Uri.parse("https://$baseUrl/prediction-monitor-nginx/predictions-lanes.geojson");
      final response = await Http.get(url);
      if (response.statusCode != 200) return;
      sgLanes = jsonDecode(response.body);
      await mapController?.style.addSource(
        mapbox.GeoJsonSource(id: "sg-lanes", data: json.encode(sgLanes)),
      );
    }

    // Define the color scheme for the layers.
    var color = [
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
          "rgb(140, 0, 65)",
          1,
          "rgb(40, 205, 80)",
        ],
        // Otherwise, show that the prediction is bad.
        600,
        "rgb(140, 0, 65)",
      ]
    ];
    // Highlight yellow if highlighted=1.
    color = [
      "case",
      [
        "==",
        ["get", "highlighted"],
        1
      ],
      "#FFFF00",
      color,
    ];

    // Increase size if highlighted=1.
    final circleRadius = [
      "case",
      [
        "==",
        ["get", "highlighted"],
        1
      ],
      10,
      3,
    ];

    // Define the label that will be displayed on top.
    final title = [
      "concat",
      ["get", "thing_name"],
      " ",
      ["get", "thing_properties_lanetype"],
    ];

    final sGLinesBGLayerExists = await mapController?.style.styleLayerExists("sg-lines-bg");
    if (sGLinesBGLayerExists != null && !sGLinesBGLayerExists) {
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

    final sGLinesLayerExists = await mapController?.style.styleLayerExists("sg-lines");
    if (sGLinesLayerExists != null && !sGLinesLayerExists) {
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

    final sGCirclesLayerExists = await mapController?.style.styleLayerExists("sg-circles");
    if (sGCirclesLayerExists != null && !sGCirclesLayerExists) {
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
      await mapController?.style.setStyleLayerProperty('sg-circles', 'circle-radius', jsonEncode(circleRadius));
    }

    final sGFirstLabelsLayerExists = await mapController?.style.styleLayerExists("sg-first-labels");
    if (sGFirstLabelsLayerExists != null && !sGFirstLabelsLayerExists) {
      await mapController?.style.addLayer(
        mapbox.SymbolLayer(
          sourceId: "sg-locs",
          id: "sg-first-labels",
          textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
          textSize: 14,
          textColor: textColor,
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
              18,
              0,
              19,
              0.75,
            ],
          ));
    }

    final sGSecondLabelsLayerExists = await mapController?.style.styleLayerExists("sg-second-labels");
    if (sGSecondLabelsLayerExists != null && !sGSecondLabelsLayerExists) {
      await mapController?.style.addLayer(
        mapbox.SymbolLayer(
          sourceId: "sg-locs",
          id: "sg-second-labels",
          textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
          textSize: 12,
          textColor: textColor,
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
              18,
              0,
              19,
              0.75,
            ],
          ));
    }
  }

  /// Highlights the search result on the map.
  Future<void> highlightOnMap(String value) async {
    if (mapController == null) return;

    final features = sgLocs["features"] as List<dynamic>;
    for (final feature in features) {
      final properties = feature["properties"] as Map<String, dynamic>;
      final sgId = properties["prediction_sg_id"] as String;
      properties["highlighted"] = sgId == value ? 1 : 0;
      if (value.isEmpty) properties.remove("highlighted");
    }
    if (await mapController?.style.styleSourceExists("sg-locs") == true) {
      final source = await mapController!.style.getSource("sg-locs");
      (source as mapbox.GeoJsonSource).updateGeoJSON(json.encode({"type": "FeatureCollection", "features": features}));
    }

    final featuresLanes = sgLanes["features"] as List<dynamic>;
    for (final feature in featuresLanes) {
      final properties = feature["properties"] as Map<String, dynamic>;
      final sgId = properties["prediction_sg_id"] as String;
      properties["highlighted"] = sgId == value ? 1 : 0;
      if (value.isEmpty) properties.remove("highlighted");
    }
    if (await mapController?.style.styleSourceExists("sg-lanes") == true) {
      final source = await mapController!.style.getSource("sg-lanes");
      (source as mapbox.GeoJsonSource)
          .updateGeoJSON(json.encode({"type": "FeatureCollection", "features": featuresLanes}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final legend = [
      SGStatusMapViewLegendElement("Keine Prognose", const Color(0xff000000)),
      SGStatusMapViewLegendElement("Schlechte oder veraltete Prognose", CI.radkulturRedDark),
      SGStatusMapViewLegendElement("Aktuelle und gute Prognose", CI.radkulturGreen),
    ];
    return AnnotatedRegionWrapper(
      bottomBackgroundColor: Theme.of(context).colorScheme.surface,
      colorMode: Theme.of(context).brightness,
      child: Scaffold(
        body: Stack(
          children: [
            AppMap(
              logoViewMargins: const Point(25, 120),
              logoViewOrnamentPosition: mapbox.OrnamentPosition.BOTTOM_LEFT,
              attributionButtonMargins: const Point(25, 120),
              attributionButtonOrnamentPosition: mapbox.OrnamentPosition.BOTTOM_RIGHT,
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
            if (settings.enableTrafficLightSearchBar)
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 12,
                      left: 86,
                      right: 12,
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Suche",
                        fillColor: Theme.of(context).colorScheme.surface,
                        filled: true,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: SmallIconButtonTertiary(
                          icon: Icons.close,
                          onPressed: () {
                            searchController.clear();
                            highlightOnMap("");
                            setState(() {});
                          },
                          color: Theme.of(context).colorScheme.onSurface,
                          fill: Colors.transparent,
                          withBorder: false,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      onChanged: highlightOnMap,
                    ),
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
                    fill: Theme.of(context).colorScheme.surface,
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
