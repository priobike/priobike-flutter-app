// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_plus.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationPlus _$LocationPlusFromJson(Map<String, dynamic> json) {
  return LocationPlus()
    ..location = json['location'] == null
        ? null
        : Location.fromJson(json['location'] as Map<String, dynamic>)
    ..latitude = (json['lat'] as num)?.toDouble()
    ..longitude = (json['lon'] as num)?.toDouble()
    ..accuracy = (json['acc'] as num)?.toDouble()
    ..altitude = (json['alt'] as num)?.toDouble()
    ..bearing = (json['bear'] as num)?.toDouble()
    ..speed = (json['speed'] as num)?.toDouble()
    ..speedKmh = (json['speedKmh'] as num)?.toDouble()
    ..time = json['time'] as String
    ..provider = json['provider'] as String
    ..nextLsaId = json['nextLsa'] as int
    ..nextSgName = json['nextSg'] as String
    ..distanceNextSG = json['dist'] as int
    ..crossAlgo = json['cross'] as int
    ..recommendedSpeedKmh = json['recSpeedKmh'] as int
    ..differenceSpeedKmh = (json['diffSpeedKmh'] as num)?.toDouble()
    ..locationUpdateInterval = json['locUpdIntvl'] as int
    ..remainingPhaseSeconds = json['leftSec'] as int
    ..lastCountdownThisLocation = json['lastCountdown'] as int
    ..isGreen = json['isGreen'] as bool
    ..isSimulation = json['isSim'] as bool
    ..isDebug = json['isDebug'] as bool
    ..errorReportCode = json['errorReportCode'] as int
    ..isAtilt = json['isAtilt'] as bool
    ..batteryLevel = json['batPerc'] as int
    ..rideID = json['rideID'] as String
    ..nextInstructionText = json['nextInstructionText'] as String
    ..nextInstructionSig = json['nextInstructionSig'] as String
    ..nextSg = json['nextSgUniqueName'] as String
    ..nextGhNode = json['nextGHNode'] as int;
}

Map<String, dynamic> _$LocationPlusToJson(LocationPlus instance) =>
    <String, dynamic>{
      'location': instance.location,
      'lat': instance.latitude,
      'lon': instance.longitude,
      'acc': instance.accuracy,
      'alt': instance.altitude,
      'bear': instance.bearing,
      'speed': instance.speed,
      'speedKmh': instance.speedKmh,
      'time': instance.time,
      'provider': instance.provider,
      'nextLsa': instance.nextLsaId,
      'nextSg': instance.nextSgName,
      'dist': instance.distanceNextSG,
      'cross': instance.crossAlgo,
      'recSpeedKmh': instance.recommendedSpeedKmh,
      'diffSpeedKmh': instance.differenceSpeedKmh,
      'locUpdIntvl': instance.locationUpdateInterval,
      'leftSec': instance.remainingPhaseSeconds,
      'lastCountdown': instance.lastCountdownThisLocation,
      'isGreen': instance.isGreen,
      'isSim': instance.isSimulation,
      'isDebug': instance.isDebug,
      'errorReportCode': instance.errorReportCode,
      'isAtilt': instance.isAtilt,
      'batPerc': instance.batteryLevel,
      'rideID': instance.rideID,
      'nextInstructionText': instance.nextInstructionText,
      'nextInstructionSig': instance.nextInstructionSig,
      'nextSgUniqueName': instance.nextSg,
      'nextGHNode': instance.nextGhNode,
    };
