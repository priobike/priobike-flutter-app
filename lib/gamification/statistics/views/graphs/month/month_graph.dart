import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:priobike/gamification/goals/services/user_goals_service.dart';
import 'package:priobike/gamification/statistics/services/graph_viewmodels.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/gamification/statistics/views/graphs/custom_bar_graph.dart';
import 'package:priobike/main.dart';

/// Displayes ride statistics for a single month. The data is obtained from a given [MonthGraphViewModel].
class MonthStatsGraph extends StatefulWidget {
  final MonthGraphViewModel viewModel;

  const MonthStatsGraph({
    Key? key,
    required this.viewModel,
  }) : super(key: key);
  @override
  State<MonthStatsGraph> createState() => _MonthStatsGraphState();
}

class _MonthStatsGraphState extends State<MonthStatsGraph> {
  /// The associated profile service.
  late UserGoalsService _goalsService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

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

  Widget getTitlesX(double value, TitleMeta meta, BuildContext context, TextStyle style) {
    if ((value + 1) % 5 > 0) return const SizedBox.shrink();
    var todayIndex = DateTime.now().day;
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Column(
        children: [
          Text(
            (value.toInt() + 1).toString(),
            style: todayIndex == value ? style.copyWith(fontWeight: FontWeight.bold) : style,
          ),
          todayIndex != value
              ? const SizedBox.shrink()
              : SizedBox.fromSize(
                  size: const Size(16, 3),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(3)),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double? goalValue;
    var infoType = widget.viewModel.rideInfoType;
    if (infoType == RideInfo.distance) {
      goalValue = _goalsService.userGoals.dailyDistanceGoalMetres / 1000;
    } else if (infoType == RideInfo.duration) {
      goalValue = _goalsService.userGoals.dailyDurationGoalMinutes;
    }
    return CustomBarGraph(
      barColor: Theme.of(context).colorScheme.primary,
      barWidth: 5,
      selectedBar: widget.viewModel.selectedIndex,
      yValues: widget.viewModel.yValues,
      goalValue: goalValue,
      getTitlesX: (value, meta) => getTitlesX(value, meta, context, Theme.of(context).textTheme.labelMedium!),
      onTap: (int? index) {
        widget.viewModel.setSelectedIndex(index);
      },
    );
  }
}
