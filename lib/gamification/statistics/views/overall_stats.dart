import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/services/user_service.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/main.dart';

class OverallStatistics extends StatefulWidget {
  const OverallStatistics({Key? key}) : super(key: key);

  @override
  State<OverallStatistics> createState() => _OverallStatisticsState();
}

class _OverallStatisticsState extends State<OverallStatistics> {
  /// Game settings service required to check whether the user has set their challenge goals.
  late GamificationUserService _profileService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  @override
  void initState() {
    _profileService = getIt<GamificationUserService>();
    _profileService.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    _profileService.removeListener(update);
    super.dispose();
  }

  /// Returns an info widget for a given value with a given label and icon.
  Widget getInfoWidget(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: CI.blue.withOpacity(1),
          ),
          BoldSmall(
            text: value,
            context: context,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
          ),
          BoldSmall(
            text: label,
            context: context,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var profile = _profileService.profile!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const VSpace(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              getInfoWidget(
                Icons.directions_bike,
                StringFormatter.getRoundedStrByRideType(profile.totalDistanceKilometres, RideInfo.distance),
                'km',
              ),
              getInfoWidget(
                Icons.timer,
                StringFormatter.getRoundedStrByRideType(profile.totalDurationMinutes, RideInfo.duration),
                'min',
              ),
              getInfoWidget(
                Icons.speed,
                'ø ${StringFormatter.getRoundedStrByRideType(profile.averageSpeedKmh, RideInfo.averageSpeed)}',
                'km/h',
              ),
              getInfoWidget(
                Icons.arrow_upward,
                StringFormatter.getRoundedStrByRideType(profile.totalElevationGainMetres, RideInfo.elevationGain),
                'm',
              ),
              getInfoWidget(
                Icons.arrow_downward,
                StringFormatter.getRoundedStrByRideType(profile.totalElevationLossMetres, RideInfo.elevationLoss),
                'm',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
