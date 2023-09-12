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
  /// The associated goals service to get the daily goals and route goals of the user.
  late GoalsService _goalsService;

  @override
  void initState() {
    _goalsService = getIt<GoalsService>();
    _goalsService.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    _goalsService.removeListener(update);
    super.dispose();
  }

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  Widget _getProgressRing({required double value, required StatType type, double progress = 1, double size = 80}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ProgressRing(
          ringColor: CI.blue.withOpacity(progress == 1 ? 1 : 0.5),
          ringSize: size,
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
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: Container(
            foregroundDecoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Theme.of(context).colorScheme.background,
                  Theme.of(context).colorScheme.background.withOpacity(0.8),
                  Theme.of(context).colorScheme.background.withOpacity(0.7),
                  Theme.of(context).colorScheme.background.withOpacity(0.7),
                  Theme.of(context).colorScheme.background.withOpacity(0.8),
                  Theme.of(context).colorScheme.background,
                ],
              ),
            ),
            child: Container(
              foregroundDecoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.background,
                    Theme.of(context).colorScheme.background.withOpacity(0.5),
                    Theme.of(context).colorScheme.background.withOpacity(0.2),
                    Theme.of(context).colorScheme.background.withOpacity(0.2),
                    Theme.of(context).colorScheme.background.withOpacity(0.5),
                    Theme.of(context).colorScheme.background,
                  ],
                ),
              ),
              child: ClipRRect(
                child: Image(
                  image: Theme.of(context).colorScheme.brightness == Brightness.dark
                      ? const AssetImage('assets/images/map-dark.png')
                      : const AssetImage('assets/images/map-light.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
              Expanded(child: Container()),
              if (_goalsService.routeGoals == null)
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    BoldSubHeader(
                      text: '',
                      context: context,
                      height: 0,
                    ),
                    const SizedBox(width: 4),
                    SubHeader(
                      text: '',
                      context: context,
                      height: 0,
                    )
                  ],
                ),
              if (_goalsService.routeGoals != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    BoldSubHeader(text: _goalsService.routeGoals!.routeName, context: context),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
