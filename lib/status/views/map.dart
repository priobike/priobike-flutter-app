import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/prediction.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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

  /// The logger for this service.
  final log = Logger("SGStatusMapViewState");

  /// The status map location features.
  Map<String, dynamic>? featuresLocs;

  /// The status map line features.
  Map<String, dynamic>? featuresLanes;

  /// Indicates if the features are currently fetched/merged/loaded.
  bool loading = true;

  /// A callback which is executed when the map was created.
  Future<void> onMapCreated(mapbox.MapboxMap controller) async {
    mapController = controller;
  }

  /// Fetch the geojsons.
  Future<Map<String, dynamic>?> fetch(String baseUrl, PredictionMode predictionMode, String fileName) async {
    try {
      var url = "https://$baseUrl/${predictionMode.statusProviderSubPath}/$fileName";
      final endpoint = Uri.parse(url);

      final response = await Http.get(endpoint).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        final err = "Error while fetching prediction status from $endpoint: ${response.statusCode}";
        throw Exception(err);
      }
      log.i("Fetched $fileName-features for status map (${predictionMode.name}).");
      return jsonDecode(response.body);
    } catch (e, stack) {
      final hint = "Error while fetching prediction status: $e";
      if (!kDebugMode) {
        Sentry.captureException(e, stackTrace: stack, hint: hint);
      }
      log.e(hint);
      return null;
    }
  }

  /// Merge the features of the prediction service and the predictor.
  Map<String, dynamic> mergeFeatureCollections(
      Map<String, dynamic> featuresPredictionService, Map<String, dynamic> featuresPredictor) {
    Map<String, dynamic> mergedFeatures = {
      "type": "FeatureCollection",
      "features": [],
    };
    int predictionServiceFeatureCount = 0;
    int predictorFeatureCount = 0;
    // Iterate over features of prediction service.
    for (var i = 0; i < featuresPredictionService["features"].length; i++) {
      final featurePredictionService = featuresPredictionService["features"][i];
      var featurePredictor =
          i >= (featuresPredictor["features"] as List).length ? null : featuresPredictor["features"][i];
      // If they are not in the same order (the index does not result in the same thing name)
      // find the predictor feature that corresponds to the prediction service feature.
      if (featurePredictor == null ||
          featurePredictionService["properties"]["thing_name"] != featurePredictor["properties"]["thing_name"]) {
        featurePredictor = featuresPredictor["features"].firstWhere(
            (element) => element["properties"]["thing_name"] == featurePredictionService["properties"]["thing_name"],
            orElse: () => null);
      }
      // If there doesn't exist a feature of the predictor that corresponds to the feature of the prediction service,
      // just take the prediction service feature.
      if (featurePredictionService["properties"]["thing_name"] != featurePredictor?["properties"]["thing_name"]) {
        mergedFeatures["features"].add(featurePredictionService);
        predictionServiceFeatureCount++;
        continue;
      }
      // If the prediction service feature contains an available prediction and the predictor feature not,
      // take the prediction service feature.
      if (featurePredictionService["properties"]["prediction_available"] &&
          !featurePredictor["properties"]["prediction_available"]) {
        mergedFeatures["features"].add(featurePredictionService);
        predictionServiceFeatureCount++;
        continue;
      }
      // If the predictor feature contains an available prediction and the prediction service feature not,
      // take the predictor feature.
      if (!featurePredictionService["properties"]["prediction_available"] &&
          featurePredictor["properties"]["prediction_available"]) {
        mergedFeatures["features"].add(featurePredictor);
        predictorFeatureCount++;
        continue;
      }
      mergedFeatures["features"].add(featurePredictionService);
      predictionServiceFeatureCount++;
    }
    log.i(
        """Used $predictionServiceFeatureCount features from prediction service and $predictorFeatureCount features from predictor during merge.
    ${featuresPredictionService["features"].length} features at prediction service and ${featuresPredictor["features"].length} features at predictor in total.
    """);
    return mergedFeatures;
  }

  /// A callback which is executed when the map style was loaded.
  Future<void> onStyleLoaded(mapbox.StyleLoadedEventData styleLoadedEventData) async {
    if (mapController == null) return;

    setState(() {
      loading = true;
    });

    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;

    // Get the location features.
    if (settings.predictionMode != PredictionMode.hybrid) {
      featuresLocs = await fetch(baseUrl, settings.predictionMode, "predictions-locations.geojson");
    } else {
      // Perform fusion of both prediction mode statuses.
      final featuresPredictionService =
          await fetch(baseUrl, PredictionMode.usePredictionService, "predictions-locations.geojson");
      final featuresPredictor = await fetch(baseUrl, PredictionMode.usePredictor, "predictions-locations.geojson");

      if (featuresPredictionService == null && featuresPredictor == null) {
        setState(() {
          loading = false;
        });
        return;
      }

      // If one endpoint doesn't return anything use the other one.
      if (featuresPredictionService == null) featuresLocs = featuresPredictor;
      if (featuresPredictor == null) featuresLocs = featuresPredictionService;

      // The actual fusion.
      featuresLocs ??= mergeFeatureCollections(featuresPredictionService!, featuresPredictor!);
    }

    if (featuresLocs == null) {
      setState(() {
        loading = false;
      });
      return;
    }

    final sourceLocsExists = await mapController?.style.styleSourceExists("sg-locs");
    if (sourceLocsExists != null && !sourceLocsExists) {
      await mapController?.style.addSource(
        mapbox.GeoJsonSource(id: "sg-locs", data: jsonEncode(featuresLocs)),
      );
    }

    // Get the lane features.
    if (settings.predictionMode != PredictionMode.hybrid) {
      featuresLanes = await fetch(baseUrl, settings.predictionMode, "predictions-lanes.geojson");
    } else {
      // Perform fusion of both prediction mode statuses.
      final featuresPredictionService =
          await fetch(baseUrl, PredictionMode.usePredictionService, "predictions-lanes.geojson");
      final featuresPredictor = await fetch(baseUrl, PredictionMode.usePredictor, "predictions-lanes.geojson");

      if (featuresPredictionService == null && featuresPredictor == null) {
        setState(() {
          loading = false;
        });
        return;
      }

      // If one endpoint doesn't return anything use the other one.
      if (featuresPredictionService == null) featuresLanes = featuresPredictor;
      if (featuresPredictor == null) featuresLanes = featuresPredictionService;

      // The actual fusion.
      featuresLanes ??= mergeFeatureCollections(featuresPredictionService!, featuresPredictor!);
    }

    if (featuresLanes == null) {
      setState(() {
        loading = false;
      });
      return;
    }

    final sourceSGLanesExists = await mapController?.style.styleSourceExists("sg-lanes");
    if (sourceSGLanesExists != null && !sourceSGLanesExists) {
      await mapController?.style.addSource(
        mapbox.GeoJsonSource(id: "sg-lanes", data: jsonEncode(featuresLanes)),
      );
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
    }

    final sGFirstLabelsLayerExists = await mapController?.style.styleLayerExists("sg-first-labels");
    if (sGFirstLabelsLayerExists != null && !sGFirstLabelsLayerExists) {
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

    final sGSecondLabelsLayerExists = await mapController?.style.styleLayerExists("sg-second-labels");
    if (sGSecondLabelsLayerExists != null && !sGSecondLabelsLayerExists) {
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
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final legend = [
      SGStatusMapViewLegendElement("Keine Prognose", const Color(0xff000000)),
      SGStatusMapViewLegendElement("Schlechte oder veraltete Prognose", CI.red),
      SGStatusMapViewLegendElement("Aktuelle und gute Prognose", CI.blue),
    ];
    final ppi = MediaQuery.of(context).devicePixelRatio * 0.9;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            AppMap(
              logoViewMargins: Point(50, 120 * ppi + MediaQuery.of(context).padding.bottom),
              logoViewOrnamentPosition: mapbox.OrnamentPosition.BOTTOM_LEFT,
              attributionButtonMargins: Point(50, 120 * ppi + MediaQuery.of(context).padding.bottom),
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
                      child: loading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : Column(
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
