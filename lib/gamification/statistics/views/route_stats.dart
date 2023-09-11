import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/goals/models/route_goals.dart';
import 'package:priobike/gamification/goals/services/goals_service.dart';
import 'package:priobike/gamification/statistics/models/ride_stats.dart';
import 'package:priobike/gamification/statistics/views/route_goals_in_week.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/main.dart';

/// A widget displaying the users route stats for a single given week.
class FancyRouteStatsForWeek extends StatefulWidget {
  /// The week displayed by the widget. 
  final WeekStats week;

  const FancyRouteStatsForWeek({Key? key, required this.week}) : super(key: key);

  @override
  State<FancyRouteStatsForWeek> createState() => _FancyRouteStatsForWeekState();
}

class _FancyRouteStatsForWeekState extends State<FancyRouteStatsForWeek> {
  /// The associated goals service to get the route goals to display, whether the user has reached the goasl.
  late GoalsService _goalsService;

  /// The current route goals of the user. 
  RouteGoals? get goals => _goalsService.routeGoals;

  /// Get shortcut corresponding to the route the users has goals for. 
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
                child: RouteGoalsInWeek(
                  goals: goals!,
                  ridesInWeek: widget.week.rides,
                  daySize: 32,
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
