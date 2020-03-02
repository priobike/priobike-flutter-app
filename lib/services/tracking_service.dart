import 'package:bikenow/config/logger.dart';
import 'package:bikenow/models/data_point.dart';
import 'package:bikenow/models/recommendation.dart';
import 'package:geolocator/geolocator.dart';

class TrackingService {
  Logger log = new Logger('TrackingService');

  bool _isTracking = false;

  Recommendation _currentRecommendation;

  TrackingService({
    Stream<Recommendation> recommendationStream,
    Stream<Position> positionStream,
  }) {
    recommendationStream.listen((Recommendation recommendation) {
      _currentRecommendation = recommendation;
    });

    positionStream.listen((newPosition) {
      if (_isTracking) {
        // TODO handle creation of TrackId
        // TODO use correct nexSgId
        DataPoint dataPoint = new DataPoint(
          trackID: 'TrackId',
          gpsLat: newPosition.latitude,
          gpsLon: newPosition.longitude,
          gpsAlt: newPosition.altitude,
          gpsSpeed: newPosition.speed,
          gpsTimestamp: new DateTime.now().toLocal().toString(),
          distanceToNextSg: _currentRecommendation.distance,
          recommendedSpeed: _currentRecommendation.speedRecommendation,
          sgIsGreen: _currentRecommendation.isGreen,
          secondsToPhaseChange: _currentRecommendation.secondsToPhaseChange,
          nextSgID: _currentRecommendation.label,
        );

        print('created new data point $dataPoint');
      }
    });
  }

  startTracking() {
    log.i('Start Tracking...');
    _isTracking = true;
  }

  stopTracking() {
    log.i('Stop Tracking...');
    _isTracking = false;
  }
}
