// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Location _$LocationFromJson(Map<String, dynamic> json) {
  return Location(
      (json['lat'] as num)?.toDouble(),
      (json['lon'] as num)?.toDouble(),
      (json['acc'] as num)?.toDouble(),
      (json['alt'] as num)?.toDouble(),
      (json['bear'] as num)?.toDouble(),
      (json['speed'] as num)?.toDouble(),
      json['time'] == null ? null : DateTime.parse(json['time'] as String),
      json['provider'] as String,
      json['nxtLsa'] as int,
      json['nxtSg'] as String,
      json['cross'] as int,
      json['dist'] as int,
      (json['recSpeedKmh'] as num)?.toDouble(),
      json['locUpdIntvl'] as int,
      json['leftSec'] as int,
      json['isGreen'] as bool,
      json['isSim'] as bool,
      json['isAtilt'] as bool,
      json['batPerc'] as num)
    ..speedKmh = (json['speedKmh'] as num)?.toDouble()
    ..diffSpeedKmh = (json['diffSpeedKmh'] as num)?.toDouble();
}

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
      'lat': instance.lat,
      'lon': instance.lon,
      'acc': instance.acc,
      'alt': instance.alt,
      'bear': instance.bear,
      'speed': instance.speed,
      'time': instance.time?.toIso8601String(),
      'provider': instance.provider,
      'nxtLsa': instance.nxtLsa,
      'nxtSg': instance.nxtSg,
      'cross': instance.cross,
      'dist': instance.dist,
      'speedKmh': instance.speedKmh,
      'recSpeedKmh': instance.recSpeedKmh,
      'diffSpeedKmh': instance.diffSpeedKmh,
      'locUpdIntvl': instance.locUpdIntvl,
      'leftSec': instance.leftSec,
      'isGreen': instance.isGreen,
      'isSim': instance.isSim,
      'isAtilt': instance.isAtilt,
      'batPerc': instance.batPerc
    };
