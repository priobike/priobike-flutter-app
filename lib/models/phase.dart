import 'package:bike_now_flutter/configuration.dart';
import 'package:bike_now_flutter/models/sg.dart';
import 'package:json_annotation/json_annotation.dart';
import 'dart:math';

import 'package:logging/logging.dart';

part 'phase.g.dart';

@JsonSerializable()
class Phase {
  String start;
  String end;
  int duration;
  bool isGreen = false;
  DateTime _endDate;

  DateTime get endDate {
    if (end != null) {
      return DateTime.parse(end);
    }
    return null;
  }

  set endDate(DateTime value) {
    _endDate = value;
  }

  DateTime _startDate;

  DateTime get startDate {
    if (start != null) {
      return DateTime.parse(start);
    }
    return null;
  }

  set startDate(DateTime value) {
    _startDate = value;
  }

  DateTime _midDate;

  DateTime get midDate {
    if (startDate != null && endDate != null) {
      var startTimestamp = startDate.millisecondsSinceEpoch;
      var endTimestamp = endDate.millisecondsSinceEpoch;
      var midTimestamp =
          (startTimestamp + ((endTimestamp - startTimestamp) / 2)).round();
      return DateTime.fromMillisecondsSinceEpoch(midTimestamp);
    }
  }

  int _durationLeft;

  int get durationLeft {
    if (startDate != null && endDate != null) {
      if (startDate.isAfter(DateTime.now())) {
        return duration;
      }

      // Otherwise calculate the time difference between the phase's end
      // and the current time and return it
      return endDate.difference(DateTime.now()).inSeconds;
    }
    return null;
  }

  set durationLeft(int value) {
    _durationLeft = value;
  }

  double _distance;

  double get distance {
    return parentSG.distance;
  }

  set distance(double value) {
    _distance = value;
  }

  double speedToReachStart;
  double speedToReachMid;
  double speedToReachEnd;
  SG parentSG;
  bool _isInThePast;

  bool get isInThePast {
    if (endDate == null) {
      return false;
    }
    return endDate.isBefore(DateTime.now());
  }

  set isInThePast(bool value) {
    _isInThePast = value;
  }

  Phase(
      this.start,
      this.end,
      this.duration,
      this.isGreen,
      this.speedToReachStart,
      this.speedToReachMid,
      this.speedToReachEnd,
      this.parentSG,
      bool isInThePast) {
    this.isInThePast = isInThePast;
  }

  factory Phase.fromJson(Map<String, dynamic> json) => _$PhaseFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$PhaseToJson(this);

  double getRecommendedSpeed() {
    if (speedToReachStart != null && speedToReachMid != null) {
      return (speedToReachStart + speedToReachMid) / 2;
    }
    return null;
  }

  double getRecommendedSpeedDifference(double currentSpeed) {
    if (getRecommendedSpeed() != null) {
      return getRecommendedSpeed() - currentSpeed;
    }
    return null;
  }

  Phase getValidPhase(double currentSpeed) {
    if (!isInThePast &&
        isGreen &&
        startDate != null &&
        midDate != null &&
        endDate != null) {
      // Convert userMaxSpeed from km/h to m/s
      var userMaxSpeed = Configuration.userMaxSpeed / 3.6;
      var currentUserMaxSpeed = [currentSpeed, userMaxSpeed].reduce(max);

      var now = DateTime.now();
      var timeDifferenceToStartFromNow = startDate.difference(now).inSeconds;
      var timeDifferenceToMidFromNow = midDate.difference(now).inSeconds;
      var timeDifferenceToEndFromNow = endDate.difference(now).inSeconds;

      if (distance != null) {
      } else {
        Logger.root.fine("The phase's distance is not set");
        return null;
      }

      // Speed to reach the end of the phase
      speedToReachEnd = distance / timeDifferenceToEndFromNow;

      // Phase is not valid, when the user cannot reach the phase end
      // with the maximum speed
      if (speedToReachEnd > currentUserMaxSpeed) {
        return null;
      }

      // Speed to reach the middle of the phase
      speedToReachMid = midDate.isAfter(DateTime.now())
          ? distance / timeDifferenceToMidFromNow
          : currentUserMaxSpeed;

      if (speedToReachMid > currentUserMaxSpeed) {
        speedToReachMid = currentUserMaxSpeed;
      }

      // Speed to reach the start of the phase
      speedToReachStart = startDate.isAfter(DateTime.now())
          ? distance / timeDifferenceToStartFromNow
          : currentUserMaxSpeed;

      if (speedToReachStart > currentUserMaxSpeed) {
        speedToReachStart = currentUserMaxSpeed;
      }
      return this;
    }
    return null;
  }

  Phase getCurrentPhase() {
    if (!isInThePast && startDate != null && endDate != null) {
      return this;
    }
    return null;
  }
}
