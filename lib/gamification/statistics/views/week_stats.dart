import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/ride_summary/ride_summary.dart';
import 'package:priobike/gamification/statistics/views/utils.dart';
import 'package:priobike/gamification/statistics/views/ride_graph.dart';

class WeekStatsView extends StatefulWidget {
  final DateTime startDay;

  final Function() tabHandler;

  final String? headerTitle;

  const WeekStatsView({
    Key? key,
    required this.startDay,
    required this.tabHandler,
    this.headerTitle,
  }) : super(key: key);

  @override
  State<WeekStatsView> createState() => _WeekStatsViewState();
}

class _WeekStatsViewState extends State<WeekStatsView> {
  /// Ride DAO required to load the rides from the db.
  final RideSummaryDao rideDao = AppDatabase.instance.rideSummaryDao;

  /// Loaded rides in a list.
  List<RideSummary> rides = [];

  final List<double> distances = List.filled(7, 0);

  int? selectedIndex;

  @override
  void initState() {
    // Listen to ride data and update local list accordingly.
    rideDao.streamSummariesOfWeek(widget.startDay).listen((update) {
      rides = update;
      calculateDistances();
      //if (!mounted) return;
      setState(() {});
    });
    super.initState();
  }

  void calculateDistances() {
    for (int i = 0; i < 7; i++) {
      var weekDay = widget.startDay.add(Duration(days: i)).day;
      var ridesOnDay = rides.where((ride) => ride.startTime.day == weekDay);
      distances[i] = StatUtils.getDistanceSum(ridesOnDay.toList());
    }
  }

  Widget getTitlesX(double value, TitleMeta meta, {required TextStyle style}) {
    var today = DateTime.now();
    var todayIndex = today.difference(widget.startDay).inDays;
    String text = StatUtils.getWeekStr(value.toInt());
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

  String getHeaderInfoText() {
    if (distances.isEmpty) {
      return '';
    } else if (selectedIndex == null) {
      return '${StatUtils.getListSumStr(distances)} km';
    } else {
      return '${StatUtils.convertDoubleToStr(distances[selectedIndex!])} km';
    }
  }

  String getSubHeader() {
    if (selectedIndex == null) {
      return StatUtils.getFromToStr(widget.startDay, widget.startDay.add(const Duration(days: 6)));
    } else {
      return StatUtils.getDateStr(widget.startDay.add(Duration(days: selectedIndex!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RideStatisticsGraph(
      maxY: StatUtils.getFittingMax(distances.max),
      barWidth: 20,
      barColor: Theme.of(context).colorScheme.primary,
      selectedBar: selectedIndex,
      yValues: distances,
      getTitlesX: (value, meta) => getTitlesX(value, meta, style: Theme.of(context).textTheme.labelMedium!),
      handleBarToucH: (int? index) async {
        if (selectedIndex == null && index == null) await widget.tabHandler();
        setState(() => selectedIndex = index);
      },
      headerSubTitle: (widget.headerTitle == null) ? '' : getSubHeader(),
      headerTitle: widget.headerTitle ?? getSubHeader(),
      headerInfoText: getHeaderInfoText(),
    );
  }
}
