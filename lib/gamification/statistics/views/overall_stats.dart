import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/services/user_service.dart';
import 'package:priobike/gamification/statistics/models/stat_type.dart';
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

  /// Returns an info widget for a given stat, label and icon.
  Widget getStatWidget(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: CI.blue.withOpacity(1),
          ),
          BoldContent(
            text: value,
            context: context,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
            height: 1,
          ),
          BoldSmall(
            text: label,
            context: context,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2),
            height: 1,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var profile = _profileService.profile!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          BoldContent(text: 'Dein PrioBike', context: context, height: 1),
          BoldSmall(
            text: 'beigetreten am ${StringFormatter.getDateStr(_profileService.profile!.joinDate)}',
            context: context,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.25),
            height: 1,
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              getStatWidget(
                Icons.directions_bike,
                StringFormatter.getRoundedStrByRideType(profile.totalDistanceKilometres, StatType.distance),
                'km',
              ),
              getStatWidget(
                Icons.timer,
                StringFormatter.getRoundedStrByRideType(profile.totalDurationMinutes, StatType.duration),
                'min',
              ),
              getStatWidget(
                Icons.speed,
                StringFormatter.getRoundedStrByRideType(profile.averageSpeedKmh, StatType.speed),
                'økm/h',
              ),
              getStatWidget(
                Icons.arrow_upward,
                StringFormatter.getRoundedStrByRideType(profile.totalElevationGainMetres, StatType.elevationGain),
                'm',
              ),
              getStatWidget(
                Icons.arrow_downward,
                StringFormatter.getRoundedStrByRideType(profile.totalElevationLossMetres, StatType.elevationLoss),
                'm',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
