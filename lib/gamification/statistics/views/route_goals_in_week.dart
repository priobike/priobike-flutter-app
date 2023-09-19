import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/goals/models/route_goals.dart';

/// This widget displays the users route goals progress for given rides in week and the route goals.
class RouteGoalsInWeek extends StatelessWidget {
  /// The route goals for the week.
  final RouteGoals goals;

  /// The list of rides in the week to be displayed.
  final List<RideSummary> ridesInWeek;

  /// The size of the widget displaying a single day of the week.
  final double daySize;

  const RouteGoalsInWeek({
    Key? key,
    required this.ridesInWeek,
    required this.goals,
    required this.daySize,
  }) : super(key: key);

  /// Returns the number of rides the user did on the route for a given weekday.
  int _ridesOnDay(int day) {
    var ridesOnDay = ridesInWeek.where((ride) => ride.startTime.weekday == day + 1);
    var ridesOnRoute = ridesOnDay.where((ride) => ride.shortcutId == goals.routeID);
    return ridesOnRoute.length;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: goals.weekdays
          .mapIndexed(
            (i, isGoal) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: daySize,
                  width: daySize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _ridesOnDay(i) > 0 && isGoal
                        ? CI.blue
                        : Theme.of(context).colorScheme.onBackground.withOpacity(isGoal ? 0.1 : 0.05),
                  ),
                  child: Center(
                    child: BoldSmall(
                      text: '${_ridesOnDay(i)}/${isGoal ? '1' : '0'}',
                      context: context,
                      color: _ridesOnDay(i) > 0 && isGoal
                          ? Colors.white
                          : Theme.of(context).colorScheme.onBackground.withOpacity(isGoal ? 1 : 0.25),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                BoldContent(text: StringFormatter.getWeekStr(i), context: context)
              ],
            ),
          )
          .toList(),
    );
  }
}
