import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/ride_summary/ride_summary.dart';
import 'package:priobike/gamification/statistics/views/ride_graph.dart';

class MultipleWeeksStatsView extends StatefulWidget {
  final DateTime firstWeekStartDay;

  final DateTime lastWeekStartDay;

  const MultipleWeeksStatsView({Key? key, required this.firstWeekStartDay, required this.lastWeekStartDay})
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

  double maxY = 0;

  int? selectedIndex;

  @override
  void initState() {
    var currentStartDay = widget.firstWeekStartDay;
    var diffToLastDay = widget.lastWeekStartDay.difference(currentStartDay).inDays;
    do {
      distances.add(0);
      rides[currentStartDay] = [];
      var startDay = currentStartDay;
      // Listen to ride data and update local list accordingly.
      rideDao.streamSummariesOfWeek(startDay).listen((update) {
        rides[startDay] = update;
        calculateDistances();
        setState(() {});
      });
      currentStartDay = currentStartDay.add(const Duration(days: 7));
      diffToLastDay = widget.lastWeekStartDay.difference(currentStartDay).inDays;
    } while (diffToLastDay >= 0);

    super.initState();
  }

  void calculateDistances() {
    rides.values.forEachIndexed((i, ridesInWeek) {
      if (ridesInWeek.isEmpty) return;
      var distanceSum = ridesInWeek.map((r) => r.distanceMetres).reduce((a, b) => a + b) / 1000;
      if (distanceSum > 10) distanceSum = distanceSum.floorToDouble();
      distances[i] = distanceSum;
    });
    maxY = distances.max;
    if (maxY > 5 && maxY <= 10) maxY = maxY.ceilToDouble();
    if (maxY > 10 && maxY <= 50) maxY = 5 * (maxY / 5).ceilToDouble();
    if (maxY > 50 && maxY <= 100) maxY = 10 * (maxY / 10).ceilToDouble();
    if (maxY > 100) maxY = 50 * (maxY / 50).ceilToDouble();
  }

  List<BarChartGroupData> getBars(Color color) {
    return distances
        .mapIndexed((i, d) => RideStatisticsGraph.createBar(
              x: i,
              y: d,
              color: color,
              selected: selectedIndex == null ? null : (selectedIndex == i),
              width: 10,
            ))
        .toList();
  }

  Widget getTitlesX(double value, TitleMeta meta, {required TextStyle style}) {
    return const SizedBox.shrink();
  }

  String getHeaderInfoText() {
    if (selectedIndex == null) {
      return '${distances.reduce((a, b) => a + b).round()} km';
    } else {
      return '${distances[selectedIndex!] < 10 ? distances[selectedIndex!] : distances[selectedIndex!].round()} km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return RideStatisticsGraph(
      maxY: maxY > 0 ? maxY : 1,
      bars: getBars(Theme.of(context).colorScheme.primary),
      getTitlesX: (value, meta) => getTitlesX(value, meta, style: Theme.of(context).textTheme.labelMedium!),
      handleBarToucH: (int? index) => setState(() => selectedIndex = index),
      headerSubTitle: selectedIndex == null ? '' : DateFormat("dd.MM").format(rides.keys.elementAt(selectedIndex!)),
      headerTitle: '10 Wochen',
      headerInfoText: getHeaderInfoText(),
    );
  }
}
