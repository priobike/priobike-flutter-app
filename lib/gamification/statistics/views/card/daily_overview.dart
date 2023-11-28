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

/// This widget displays a simple overview of the daily statistics of a user, including their daily goals (if set).
class DailyOverview extends StatefulWidget {
  /// The day to be displayed.
  final DayStats today;

  const DailyOverview({super.key, required this.today});

  @override
  State<DailyOverview> createState() => _DailyOverviewState();
}

class _DailyOverviewState extends State<DailyOverview> {
  /// The associated goals service to get the daily goals and route goals of the user.
  late GoalsService _goalsService;

  /// How many rides the user did on the route target for the day, if there is one.
  int get _ridesOnRouteGoal => _hasRouteGoal
      ? widget.today.rides.where((ride) => ride.shortcutId == _goalsService.routeGoals!.routeID).length
      : 0;

  /// Whether the user has set route goals for the day.
  bool get _hasRouteGoal =>
      _goalsService.routeGoals != null && _goalsService.routeGoals!.weekdays.elementAt(widget.today.date.weekday - 1);

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

  /// This widget displays the progress a user has made for a certain value.
  Widget _getProgressRing({
    required double value,
    required StatType type,
    double progress = 1,
    double size = 80,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ProgressRing(
          ringColor: CI.radkulturRed.withOpacity(progress >= 1 ? 1 : 0.5),
          ringSize: size,
          progress: progress,
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 4),
              BoldSubHeader(
                text: StringFormatter.getRoundedStrByStatType(value, type),
                context: context,
                height: 0,
              ),
              BoldContent(
                text: StringFormatter.getLabelForStatType(type),
                context: context,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                height: 0,
              ),
            ],
          ),
        ),
        BoldContent(text: StringFormatter.getDescriptionForStatType(type), context: context),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const SmallHSpace(),
                  BoldSubHeader(
                    text: 'Heute',
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
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: !_hasRouteGoal
                      ? Theme.of(context).colorScheme.onBackground.withOpacity(0.1)
                      : (_ridesOnRouteGoal >= 1
                          ? CI.radkulturRed.withOpacity(1)
                          : Theme.of(context).colorScheme.onBackground.withOpacity(0.1)),
                ),
                child: BoldContent(
                  text: !_hasRouteGoal
                      ? 'Kein Routenziel für Heute'
                      : '$_ridesOnRouteGoal/1 ${_goalsService.routeGoals!.routeName}',
                  context: context,
                  height: 1,
                ),
              ),
              Expanded(child: Container()),
            ],
          ),
        ),
      ],
    );
  }
}
