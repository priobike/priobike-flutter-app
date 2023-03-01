import 'package:priobike/ride/interfaces/prediction.dart';
import 'package:priobike/ride/models/recommendation.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/status/messages/sg.dart';

abstract class PredictionComponent {
  /// The current prediction received during the ride.
  Prediction? get prediction;

  /// The current calculated recommendation during the ride.
  Recommendation? get recommendation;

  /// A callback that gets executed when the parent provider should call the notifyListeners function.
  late final Function notifyListeners;

  /// The callback that gets executed when a new prediction
  /// was received from the prediction service and a new
  /// status update was calculated based on the prediction.
  late final Function(SGStatusData)? onNewPredictionStatusDuringRide;

  /// Subscribe to the signal group.
  /// The return value specifies whether the client unsubscribed from a previous signal group.
  bool selectSG(Sg? sg);

  /// Establish a connection with the MQTT client.
  Future<void> connectMQTTClient();

  /// Stop the navigation.
  Future<void> stopNavigation();

  /// Reset the service.
  Future<void> reset();
}
