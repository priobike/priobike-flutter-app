import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/custom_game_icons.dart';
import 'package:priobike/gamification/common/services/user_service.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/statistics/models/stat_type.dart';
import 'package:priobike/main.dart';

/// Widget to display the overall statistics of the users registered rides since enabling the gamification.
class OverallStatistics extends StatefulWidget {
  const OverallStatistics({super.key});

  @override
  State<OverallStatistics> createState() => _OverallStatisticsState();
}

class _OverallStatisticsState extends State<OverallStatistics> {
  /// Service to pull the stats from.
  late GamificationUserService _userService;

  @override
  void initState() {
    _userService = getIt<GamificationUserService>();
    _userService.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    _userService.removeListener(update);
    super.dispose();
  }

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  /// Returns an info widget for a given stat, label and icon.
  Widget _getStatWidget(IconData icon, double value, StatType type) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          BoldContent(
            text: StringFormatter.getRoundedStrByStatType(value, type),
            context: context,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            height: 1,
          ),
          BoldSmall(
            text: StringFormatter.getLabelForStatType(type),
            context: context,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            height: 1,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var profile = _userService.profile!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          BoldContent(
              text: 'Beta-Features', context: context, height: 1, color: Theme.of(context).colorScheme.onSurface),
          Text(
            'aktiviert am ${StringFormatter.getDateStr(_userService.profile!.joinDate)}',
            style: TextStyle(
              fontFamily: 'HamburgSans',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              height: 1,
            ),
          ),
          const VSpace(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _getStatWidget(Icons.directions_bike, profile.totalDistanceKilometres, StatType.distance),
              _getStatWidget(Icons.timer, profile.totalDurationMinutes, StatType.duration),
              _getStatWidget(Icons.speed, profile.averageSpeedKmh, StatType.speed),
              _getStatWidget(CustomGameIcons.elevation_gain, profile.totalElevationGainMetres, StatType.elevationGain),
              _getStatWidget(CustomGameIcons.elevation_loss, profile.totalElevationLossMetres, StatType.elevationLoss),
            ],
          ),
        ],
      ),
    );
  }
}
