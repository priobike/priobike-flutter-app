import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/services/profile_service.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/statistics/services/graph_viewmodels.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/gamification/statistics/views/graphs/custom_bar_graph.dart';
import 'package:priobike/main.dart';

/// Displayes ride statistics for a single week. The data is obtained from a given [WeekGraphViewModel].
class WeekStatsGraph extends StatefulWidget {
  final Function() tabHandler;

  final WeekGraphViewModel viewModel;

  const WeekStatsGraph({
    Key? key,
    required this.tabHandler,
    required this.viewModel,
  }) : super(key: key);
  @override
  State<WeekStatsGraph> createState() => _WeekStatsGraphState();
}

class _WeekStatsGraphState extends State<WeekStatsGraph> {
  /// The associated profile service.
  late GameProfileService _profileService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  @override
  void initState() {
    _profileService = getIt<GameProfileService>();
    _profileService.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    _profileService.removeListener(update);
    super.dispose();
  }

  Widget getTitlesX(double value, TitleMeta meta, BuildContext context, TextStyle style) {
    var today = DateTime.now();
    var todayIndex = today.difference(widget.viewModel.startDay).inDays;
    String text = StringFormatter.getWeekStr(value.toInt());
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Column(
        children: [
          Text(
            text,
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
      goalValue = _profileService.challengeGoals.dailyDistanceGoalMetres / 1000;
    } else if (infoType == RideInfo.duration) {
      goalValue = _profileService.challengeGoals.dailyDurationGoalMinutes;
    }
    return CustomBarGraph(
      barWidth: 20,
      barColor: Theme.of(context).colorScheme.primary,
      selectedBar: widget.viewModel.selectedIndex,
      yValues: widget.viewModel.yValues,
      goalValue: goalValue,
      getTitlesX: (value, meta) => getTitlesX(value, meta, context, Theme.of(context).textTheme.labelMedium!),
      onTap: (int? index) async {
        if (widget.viewModel.selectedIndex == null && index == null) await widget.tabHandler();
        widget.viewModel.setSelectedIndex(index);
      },
    );
  }
}
