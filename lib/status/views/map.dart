import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/common/map/view.dart';
import 'package:priobike/http.dart';
import 'package:priobike/main.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/prediction.dart';
import 'package:priobike/settings/services/settings.dart';

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

  /// The geojson features currently displayed.
  Map<String, dynamic> predictionsLocations = {};

  /// The subscribed signal groups, by their sg id.
  Map<String, Map<String, dynamic>> subscribedPredictionsLocations = {};

  /// The received predictions by their sg id.
  Map<String, PredictionServicePrediction> receivedPredictions = {};

  /// The timer that updates the map every second.
  Timer? updateTimer;

  /// The prediction client.
  MqttServerClient? client;

  /// A callback which is executed when the map was created.
  Future<void> onMapCreated(mapbox.MapboxMap controller) async {
    mapController = controller;
  }

  /// Establish a connection with the MQTT client.
  Future<void> connectMQTTClient() async {
    // Get the backend that is currently selected.
    final settings = getIt<Settings>();
    final clientId = 'priobike-app-status-view-${UniqueKey().toString()}';
    try {
      client = MqttServerClient(
        settings.backend.predictionServiceMQTTPath,
        clientId,
      );
      client!.logging(on: false);
      client!.keepAlivePeriod = 30;
      client!.secure = false;
      client!.port = settings.backend.predictionServiceMQTTPort;
      client!.autoReconnect = true;
      client!.resubscribeOnAutoReconnect = true;
      client!.onDisconnected = () => log.i("Prediction MQTT client disconnected");
      client!.onConnected = () => log.i("Prediction MQTT client connected");
      client!.onSubscribed = (topic) => log.i("Prediction MQTT client subscribed to $topic");
      client!.onUnsubscribed = (topic) => log.i("Prediction MQTT client unsubscribed from $topic");
      client!.onAutoReconnect = () => log.i("Prediction MQTT client auto reconnect");
      client!.onAutoReconnected = () => log.i("Prediction MQTT client auto reconnected");
      client!.setProtocolV311(); // Default Mosquitto protocol
      client!.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(client!.clientIdentifier)
          .startClean()
          .withWillQos(MqttQos.atMostOnce);
      log.i("Connecting to Prediction MQTT broker.");
      await client!
          .connect(
            settings.backend.predictionServiceMQTTUsername,
            settings.backend.predictionServiceMQTTPassword,
          )
          .timeout(const Duration(seconds: 5));
      client!.updates?.listen(onData);

      subscribedPredictionsLocations = {};
    } catch (e) {
      client = null;
      final hint = "Failed to connect the prediction MQTT client: $e";
      log.e(hint);
    }
  }

  @override
  void initState() {
    super.initState();
    // Connect the MQTT client.
    connectMQTTClient();
    // Start the update timer.
    updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (mapController == null) return;

      final featureCollection = <String, dynamic>{
        "type": "FeatureCollection",
        "features": <dynamic>[],
      };

      for (final prediction in receivedPredictions.values) {
        // Check if we have all necessary information.
        if (prediction.greentimeThreshold == -1) continue;
        if (prediction.predictionQuality == -1) continue;
        if (prediction.value.isEmpty) continue;
        // Calculate the seconds since the start of the prediction.
        final now = DateTime.now();
        final secondsSinceStart = max(0, now.difference(prediction.startTime).inSeconds);
        // Chop off the seconds that are not in the prediction vector.
        final secondsInVector = prediction.value.length;
        if (secondsSinceStart >= secondsInVector) continue;
        // Calculate the current vector.
        final currentVector = prediction.value.sublist(secondsSinceStart);
        if (currentVector.isEmpty) continue;
        // Calculate the seconds to the next phase change.
        int secondsToPhaseChange = 0;
        // Check if the phase changes within the current vector.
        bool greenNow = currentVector[0] >= prediction.greentimeThreshold;
        for (int i = 1; i < currentVector.length; i++) {
          final greenThen = currentVector[i] >= prediction.greentimeThreshold;
          if ((greenNow && !greenThen) || (!greenNow && greenThen)) {
            break;
          }
          secondsToPhaseChange++;
        }

        final baseFeature = subscribedPredictionsLocations[prediction.signalGroupId];
        if (baseFeature == null) continue;

        final feature = <String, dynamic>{
          "type": "Feature",
          "geometry": baseFeature["feature"]["geometry"],
          "properties": <String, dynamic>{
            "greenNow": greenNow,
            "countdown": secondsToPhaseChange,
          },
        };

        featureCollection["features"].add(feature);
      }

      // Update the map.
      final sourceExists = await mapController!.style.styleSourceExists("sg-predictions");
      if (sourceExists) {
        final source = await mapController!.style.getSource("sg-predictions");
        (source as mapbox.GeoJsonSource).updateGeoJSON(json.encode(featureCollection));
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    // Disconnect the MQTT client.
    client?.disconnect();
    // Cancel the update timer.
    updateTimer?.cancel();
  }

  /// A callback that is executed when data arrives.
  Future<void> onData(List<MqttReceivedMessage<MqttMessage>>? messages) async {
    if (messages == null) return;
    for (final message in messages) {
      final recMess = message.payload as MqttPublishMessage;
      // Decode the payload.
      final data = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final json = jsonDecode(data);
      final prediction = PredictionServicePrediction.fromJson(json);
      log.i("Received prediction from prediction service: $prediction");

      receivedPredictions[json["signalGroupId"]] = prediction;
    }
  }

  /// A callback which is executed when the camera was moved.
  Future<void> onCameraChanged(mapbox.CameraChangedEventData data) async {
    // Get the current focused location.
    final camera = await mapController?.getCameraState();
    if (camera == null) return;
    if (camera.center["coordinates"] == null) return;
    // Cast from Object to List [lon, lat].
    final coordinates = camera.center["coordinates"] as List;
    if (coordinates.length != 2) return;
    final lat = double.parse(coordinates[1].toStringAsFixed(4));
    final lon = double.parse(coordinates[0].toStringAsFixed(4));
    // Get the nearest 20 prediction locations.
    final features = predictionsLocations["features"] as List?;
    if (features == null) return;
    double euclidianDistance(double x1, double y1, double x2, double y2) => sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
    var nearest = features
        .map((e) => {
              "distance": euclidianDistance(lat, lon, e["geometry"]["coordinates"][1], e["geometry"]["coordinates"][0]),
              "feature": e,
            })
        .toList()
      ..sort((a, b) => a["distance"].compareTo(b["distance"]));
    nearest = nearest.sublist(0, min(30, nearest.length));
    final nearestIds = nearest.map((e) => e["feature"]["properties"]["prediction_sg_id"] as String).toList();

    // Unsubscribe from all signal groups that are not in the nearest.
    final subscribedIds = subscribedPredictionsLocations.keys.toList();
    for (final id in subscribedIds) {
      if (!nearestIds.contains(id)) {
        client?.unsubscribe("hamburg/$id");
        subscribedPredictionsLocations.remove(id);
        receivedPredictions.remove(id);
      }
    }

    // Subscribe to all signal groups that are not yet subscribed.
    for (final signalGroupFeature in nearest) {
      final id = signalGroupFeature["feature"]["properties"]["prediction_sg_id"] as String;
      if (!subscribedPredictionsLocations.containsKey(id)) {
        client?.subscribe("hamburg/$id", MqttQos.atMostOnce);
        subscribedPredictionsLocations[id] = signalGroupFeature;
      }
    }
  }

  /// A callback which is executed when the map style was loaded.
  Future<void> onStyleLoaded(mapbox.StyleLoadedEventData styleLoadedEventData) async {
    if (mapController == null) return;

    final textColor =
        Theme.of(context).colorScheme.brightness == Brightness.dark ? Colors.white.value : Colors.black.value;

    final settings = getIt<Settings>();
    final baseUrl = settings.backend.path;
    final statusProviderSubPath = settings.predictionMode.statusProviderSubPath;

    final sourceLocsExists = await mapController?.style.styleSourceExists("sg-locs");
    if (sourceLocsExists != null && !sourceLocsExists) {
      // Load the geojson data from the backend.
      try {
        final url = Uri.parse("https://$baseUrl/$statusProviderSubPath/predictions-locations.geojson");
        final response = await Http.get(url).timeout(const Duration(seconds: 4));
        if (response.statusCode != 200) {
          final err = "Failed to load predictions-locations.geojson: ${response.statusCode}";
          throw Exception(err);
        }

        final geoJson = jsonDecode(response.body) as Map<String, dynamic>;
        predictionsLocations = geoJson;
        await mapController?.style.addSource(
          mapbox.GeoJsonSource(id: "sg-locs", data: response.body),
        );
      } catch (e) {
        final hint = "Failed to load articles: $e";
        log.e(hint);
      }
    }

    final sourceSGLanesExists = await mapController?.style.styleSourceExists("sg-lanes");
    if (sourceSGLanesExists != null && !sourceSGLanesExists) {
      await mapController?.style.addSource(
        mapbox.GeoJsonSource(id: "sg-lanes", data: "https://$baseUrl/$statusProviderSubPath/predictions-lanes.geojson"),
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
      await mapController?.style.setStyleLayerProperty(
          'sg-first-labels',
          'text-field',
          jsonEncode(
            ["get", "thing_name"],
          ));
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

    final sourcePredictionsExists = await mapController?.style.styleSourceExists("sg-predictions");
    if (sourcePredictionsExists != null && !sourcePredictionsExists) {
      final emptyFeatureCollection = {
        "type": "FeatureCollection",
        "features": [],
      };
      await mapController?.style.addSource(
        mapbox.GeoJsonSource(id: "sg-predictions", data: jsonEncode(emptyFeatureCollection)),
      );
    }

    final layerPredictionsExists = await mapController?.style.styleLayerExists("sg-predictions");
    if (layerPredictionsExists != null && !layerPredictionsExists) {
      await mapController?.style.addLayer(
        mapbox.CircleLayer(
          id: "sg-predictions",
          sourceId: "sg-predictions",
          circleRadius: 10,
          circleColor: Colors.white.value,
        ),
      );

      await mapController?.style.setStyleLayerProperty(
        "sg-predictions",
        "circle-color",
        jsonEncode([
          "case",
          [
            "==",
            ["get", "greenNow"],
            false
          ],
          "#ff0000",
          [
            "==",
            ["get", "greenNow"],
            true
          ],
          "#00ff00",
          "#000000",
        ]),
      );
    }

    final layerPredictionsCountdownExists = await mapController?.style.styleLayerExists("sg-predictions-countdown");
    if (layerPredictionsCountdownExists != null && !layerPredictionsCountdownExists) {
      await mapController?.style.addLayer(
        mapbox.SymbolLayer(
          sourceId: "sg-predictions",
          id: "sg-predictions-countdown",
          textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
          textSize: 12,
          textColor: Colors.white.value,
          textAllowOverlap: true,
          textHaloColor: Colors.black.value,
          textHaloWidth: 1,
        ),
      );

      await mapController?.style.setStyleLayerProperty(
          'sg-predictions-countdown',
          'text-field',
          jsonEncode(
            ["get", "countdown"],
          ));
      await mapController?.style.setStyleLayerProperty(
          'sg-predictions-countdown',
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
              onCameraChanged: onCameraChanged,
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
