import 'package:priobike/common/models/point.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/models/recommendation.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/status/messages/sg.dart';

class Crossing {
  /// The id of the crossing.
  final String id;

  /// The SGs of the crossing.
  final List<Sg> signalGroups;

  /// A list of sg distances on the route, in the order of `signalGroups`.
  final List<double> signalGroupsDistancesOnRoute;

  /// The center of the crossing.
  late final Point position;

  /// The current predictions.
  Map<String, PredictionServicePrediction> predictions = {};

  /// The current recommendation, calculated periodically.
  Map<String, Recommendation> recommendations = {};

  /// The status data of the current predictions.
  Map<String, SGStatusData> currentSGStatusDataList = {};

  /// A callback that gets executed when the parent provider should call the notifyListeners function.
  Function? notifyListeners;

  /// The callback that gets executed when a new prediction
  /// was received from the prediction service and a new
  /// status update was calculated based on the prediction.
  Function(SGStatusData)? onNewPredictionStatusDuringRide;

  Crossing(
      {required this.id,
      required this.signalGroups,
      required this.signalGroupsDistancesOnRoute,
      required this.position});

  /// Called when the crossing is selected.
  void onSelected(Function notifyListeners, Function(SGStatusData)? onNewPredictionStatusDuringRide) {
    this.notifyListeners = notifyListeners;
    this.onNewPredictionStatusDuringRide = onNewPredictionStatusDuringRide;
  }

  /// Called when the crossing is unselected.
  void onUnselected() {
    notifyListeners = null;
    onNewPredictionStatusDuringRide = null;
  }

  /// Add a new prediction to the list of predictions (for each signal group ID only one prediction (the latest)).
  void addPrediction(PredictionServicePrediction prediction) {
    predictions[prediction.signalGroupId] = (prediction);
  }

  /// Add a new status data to the list of status data (for each signal group ID only one status data (the latest)).
  void addSGStatusData(SGStatusData sgStatusData) {
    currentSGStatusDataList[sgStatusData.thingName] = (sgStatusData);
  }

  /// Update the predictions (called periodically).
  void update() {
    for (final prediction in predictions.values) {
      calculateRecommendation(prediction);
    }
  }

  Future<void> calculateRecommendation(PredictionServicePrediction prediction) async {
    final recommendation = await prediction.calculateRecommendation();
    if (recommendation != null) recommendations[prediction.signalGroupId] = recommendation;

    // Set the prediction status of the current prediction. Needs to be set before notifyListeners() is called,
    // because based on that (if used) the hybrid mode selects the used prediction component.
    final currentSGStatusData = SGStatusData(
      statusUpdateTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      thingName:
          "hamburg/${prediction.signalGroupId}", // Same as thing name. The prefix "hamburg/" is needed to match the naming schema of the status cache.
      predictionQuality: prediction.predictionQuality,
      predictionTime: prediction.startTime.millisecondsSinceEpoch ~/ 1000,
    );

    // Needs to be called before onNewPredictionStatusDuringRide() to ensure that (if used) the hybrid mode selects the
    // used prediction component before correctly.
    notifyListeners?.call();

    // Notify that a new prediction status was obtained.
    onNewPredictionStatusDuringRide?.call(currentSGStatusData);
  }
}
