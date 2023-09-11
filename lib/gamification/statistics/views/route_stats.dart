import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/goals/models/route_goals.dart';
import 'package:priobike/gamification/goals/services/goals_service.dart';
import 'package:priobike/gamification/statistics/services/stats_view_model.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/main.dart';

class RouteStatistics extends StatefulWidget {
  final StatisticsViewModel viewModel;

  const RouteStatistics({Key? key, required this.viewModel}) : super(key: key);

  @override
  State<RouteStatistics> createState() => _RouteStatisticsState();
}

class _RouteStatisticsState extends State<RouteStatistics> {
  /// The associated goals service.
  late GoalsService _goalsService;

  RouteGoals? get goals => _goalsService.routeGoals;

  Shortcut? get routeShortcut => getIt<Shortcuts>().shortcuts?.where((s) => s.id == goals!.routeID).firstOrNull;

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

  @override
  Widget build(BuildContext context) {
    if (goals == null) {
      return Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            children: [
              const SmallHSpace(),
              BoldSubHeader(
                text: 'Routenziele',
                context: context,
                textAlign: TextAlign.start,
              ),
            ],
          ),
          Expanded(
            child: Column(
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
            ),
          ),
        ],
      );
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: Container(
            foregroundDecoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 0.7,
                colors: [
                  Theme.of(context).colorScheme.background.withOpacity(0.3),
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
        Positioned.fill(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BoldSubHeader(text: goals!.routeName, context: context),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.5, 0.9],
                    colors: [
                      Theme.of(context).colorScheme.background,
                      Theme.of(context).colorScheme.background.withOpacity(0.25),
                    ],
                  ),
                ),
                child: RoutesInWeekWidget(
                  weekGoals: goals!.weekdays,
                  ridesInWeek: widget.viewModel.weeks.last.rides,
                  routeId: goals!.routeID,
                  buttonSize: 32,
                ),
              ),
            ],
          ),
        ),
        if (routeShortcut != null) routeShortcut!.getRepresentation(),
      ],
    );
  }
}

class RoutesInWeekWidget extends StatelessWidget {
  final String routeId;
  final List<bool> weekGoals;
  final List<RideSummary> ridesInWeek;
  final double buttonSize;

  const RoutesInWeekWidget({
    Key? key,
    required this.weekGoals,
    required this.ridesInWeek,
    required this.routeId,
    required this.buttonSize,
  }) : super(key: key);

  List<int> get weekPerformance {
    var performance = List.filled(DateTime.daysPerWeek, 0);
    for (int i = 0; i < DateTime.daysPerWeek; i++) {
      var ridesOnDay = ridesInWeek.where((ride) => ride.startTime.weekday == i + 1);
      var ridesOnRoute = ridesOnDay.where((ride) => ride.shortcutId == routeId);
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
            (i, isGoal) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: buttonSize,
                  width: buttonSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: weekPerformance[i] > 0 && isGoal
                        ? CI.blue
                        : Theme.of(context).colorScheme.onBackground.withOpacity(isGoal ? 0.1 : 0.05),
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
                const SizedBox(height: 4),
                BoldContent(text: StringFormatter.getWeekStr(i), context: context)
              ],
            ),
          )
          .toList(),
    );
  }
}
