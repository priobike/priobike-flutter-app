import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/ride_summary/ride_summary.dart';
import 'package:priobike/gamification/statistics/views/utils.dart';
import 'package:priobike/gamification/statistics/views/ride_graph.dart';

class MultipleWeeksStatsView extends StatefulWidget {
  final DateTime lastWeekStartDay;

  final int numOfWeeks;

  final Function() tabHandler;

  const MultipleWeeksStatsView(
      {Key? key, required this.lastWeekStartDay, required this.numOfWeeks, required this.tabHandler})
      : super(key: key);

  @override
  State<MultipleWeeksStatsView> createState() => _MultipleWeeksStatsViewState();
}

class _MultipleWeeksStatsViewState extends State<MultipleWeeksStatsView> {
  /// Ride DAO required to load the rides from the db.
  final RideSummaryDao rideDao = AppDatabase.instance.rideSummaryDao;

  /// Loaded rides in a list.
  final Map<DateTime, List<RideSummary>> rides = {};

  final List<double> distances = [];

  int? selectedIndex;

  @override
  void initState() {
    var tmpStartDay = widget.lastWeekStartDay;
    tmpStartDay = tmpStartDay.subtract(Duration(days: 7 * (widget.numOfWeeks - 1)));

    for (int i = 0; i < widget.numOfWeeks; i++) {
      distances.add(0);
      rides[tmpStartDay] = [];
      var startDay = tmpStartDay;
      // Listen to ride data and update local list accordingly.
      rideDao.streamSummariesOfWeek(startDay).listen((update) {
        rides[startDay] = update;
        calculateDistances();
        setState(() {});
      });
      tmpStartDay = tmpStartDay.add(const Duration(days: 7));
    }

    super.initState();
  }

  void calculateDistances() {
    rides.values.forEachIndexed((i, ridesInWeek) => distances[i] = StatUtils.getDistanceSum(ridesInWeek));
  }

  Widget getTitlesX(double value, TitleMeta meta, {required TextStyle style}) {
    var today = DateTime.now();
    var difference = today.difference(rides.keys.elementAt(value.toInt())).inDays;
    var todayInWeek = difference < 7;
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Column(
        children: [
          Text(
            StatUtils.getDateStr(rides.keys.elementAt(value.toInt())),
            style: todayInWeek ? style.copyWith(fontWeight: FontWeight.bold) : style,
          ),
          !todayInWeek
              ? const SizedBox.shrink()
              : SizedBox.fromSize(
                  size: const Size(32, 3),
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

  String getSubTitle() {
    if (selectedIndex == null) {
      return StatUtils.getFromToStr(rides.keys.first, rides.keys.last.add(const Duration(days: 6)));
    }
    var currentWeekFirstDay = rides.keys.elementAt(selectedIndex!);
    return StatUtils.getFromToStr(currentWeekFirstDay, currentWeekFirstDay.add(const Duration(days: 6)));
  }

  @override
  Widget build(BuildContext context) {
    return RideStatisticsGraph(
      maxY: StatUtils.getFittingMax(distances.max),
      barColor: Theme.of(context).colorScheme.primary,
      yValues: distances,
      barWidth: 30,
      selectedBar: selectedIndex,
      getTitlesX: (value, meta) => getTitlesX(value, meta, style: Theme.of(context).textTheme.labelSmall!),
      handleBarToucH: (int? index) async {
        if (selectedIndex == null && index == null) await widget.tabHandler();
        setState(() => selectedIndex = index);
      },
      headerSubTitle: getSubTitle(),
      headerTitle: 'Letzten 5 Wochen',
      headerInfoText: getHeaderInfoText(),
    );
  }
}
