import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/ride_summary/ride_summary.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/goals/models/route_goals.dart';
import 'package:priobike/gamification/goals/services/user_goals_service.dart';
import 'package:priobike/gamification/statistics/services/graph_viewmodels.dart';
import 'package:priobike/main.dart';

class RouteStatistics extends StatefulWidget {
  final MultipleWeeksGraphViewModel viewModel;

  const RouteStatistics({Key? key, required this.viewModel}) : super(key: key);

  @override
  State<RouteStatistics> createState() => _RouteStatisticsState();
}

class _RouteStatisticsState extends State<RouteStatistics> {
  /// The associated profile service.
  late UserGoalsService _goalsService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  RouteGoals? get goals => _goalsService.routeGoals;

  @override
  void initState() {
    _goalsService = getIt<UserGoalsService>();
    _goalsService.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    _goalsService.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (goals == null) {
      return Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map,
            size: 64,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.25),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: BoldContent(
              text: 'Noch keine Routenziele gesetzt',
              context: context,
              textAlign: TextAlign.center,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.25),
            ),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: widget.viewModel.rideMap.values
          .map((rides) => WeekWidget(
                weekGoals: goals!.weekdays,
                ridesInWeek: rides,
                routeId: goals!.routeID,
              ))
          .toList(),
    );
  }
}

class WeekWidget extends StatelessWidget {
  final String routeId;
  final List<bool> weekGoals;
  final List<RideSummary> ridesInWeek;

  const WeekWidget({
    Key? key,
    required this.weekGoals,
    required this.ridesInWeek,
    required this.routeId,
  }) : super(key: key);

  List<int> get weekPerformance {
    var performance = List.filled(DateTime.daysPerWeek, 0);
    for (int i = 0; i < DateTime.daysPerWeek; i++) {
      var ridesOnDay = ridesInWeek.where((ride) => ride.startTime.weekday == i + 1);
      var ridesOnRoute = ridesOnDay.where((ride) => ride.shortcutId != routeId);
      performance[i] = ridesOnRoute.length;
    }
    return performance;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: weekGoals
          .mapIndexed(
            (i, isGoal) => Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: weekPerformance[i] > 0
                    ? CI.blue.withOpacity(isGoal ? 1 : 0.1)
                    : Theme.of(context).colorScheme.onBackground.withOpacity(isGoal ? 0.1 : 0.05),
                //border: isGoal ? Border.all(color: CI.blue, width: 2) : null,
              ),
              child: Center(
                child: BoldSmall(
                  text: '${weekPerformance[i]}/${isGoal ? '1' : '0'}',
                  context: context,
                  color: weekPerformance[i] > 0 && isGoal
                      ? Colors.white
                      : Theme.of(context).colorScheme.onBackground.withOpacity(isGoal ? 1 : 0.25),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
