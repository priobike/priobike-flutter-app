import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/progress_ring.dart';
import 'package:priobike/gamification/goals/services/goals_service.dart';
import 'package:priobike/gamification/statistics/models/ride_stats.dart';
import 'package:priobike/gamification/statistics/models/stat_type.dart';
import 'package:priobike/main.dart';

class DailyOverview extends StatefulWidget {
  final DayStats today;

  const DailyOverview({Key? key, required this.today}) : super(key: key);

  @override
  State<DailyOverview> createState() => _DailyOverviewState();
}

class _DailyOverviewState extends State<DailyOverview> {
  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  Widget _getProgressRing({required double value, required StatType type, double progress = 1}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ProgressRing(
          ringColor: CI.blue.withOpacity(progress == 1 ? 1 : 0.5),
          ringSize: 80,
          progress: progress,
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 4),
              BoldSubHeader(
                text: StringFormatter.getRoundedStrByRideType(value, type),
                context: context,
                height: 0,
              ),
              BoldContent(
                text: StringFormatter.getLabelForRideType(type),
                context: context,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                height: 0,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const SmallHSpace(),
            BoldSubHeader(
              text: widget.today.getTimeDescription(null),
              context: context,
              textAlign: TextAlign.start,
            ),
          ],
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SmallVSpace(),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _getProgressRing(
                    value: widget.today.distanceKilometres,
                    type: StatType.distance,
                    progress: widget.today.distanceGoalKilometres == null
                        ? 1
                        : widget.today.distanceKilometres / widget.today.distanceGoalKilometres!,
                  ),
                  _getProgressRing(
                    value: widget.today.durationMinutes,
                    type: StatType.duration,
                    progress: widget.today.durationGoalMinutes == null
                        ? 1
                        : widget.today.durationMinutes / widget.today.durationGoalMinutes!,
                  ),
                  _getProgressRing(
                    value: widget.today.averageSpeedKmh,
                    type: StatType.speed,
                    progress: 1,
                  ),
                ],
              ),
              /*
              const SmallVSpace(),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: Container()),
                  const Icon(
                    Icons.arrow_upward,
                    color: CI.blue,
                    size: 24,
                  ),
                  BoldContent(text: '35 m', context: context),
                  Expanded(child: Container()),
                  const Icon(
                    Icons.arrow_downward,
                    color: CI.blue,
                    size: 24,
                  ),
                  BoldContent(text: '35 m', context: context),
                  Expanded(child: Container()),
                ],
              ),*/
              Expanded(child: Container()),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.place,
                    color: CI.blue,
                    size: 32,
                  ),
                  BoldContent(text: 'Deine Route (0/1)', context: context),
                ],
              ),
              Expanded(child: Container()),
            ],
          ),
        ),
      ],
    );
  }
}
