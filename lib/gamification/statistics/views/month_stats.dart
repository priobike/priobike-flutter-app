import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/ride_summary/ride_summary.dart';
import 'package:priobike/gamification/statistics/views/ride_graph.dart';

class MonthStatsView extends StatefulWidget {
  final DateTime firstDay;

  const MonthStatsView({Key? key, required this.firstDay}) : super(key: key);

  @override
  State<MonthStatsView> createState() => _MonthStatsViewState();
}

class _MonthStatsViewState extends State<MonthStatsView> {
  /// Ride DAO required to load the rides from the db.
  final RideSummaryDao rideDao = AppDatabase.instance.rideSummaryDao;

  /// Loaded rides in a list.
  List<RideSummary> rides = [];

  late List<double> distances;

  double maxY = 0;

  int? selectedIndex;

  late int numberOfDays;

  @override
  void initState() {
    numberOfDays = getNumberOfDays();
    distances = List.filled(numberOfDays, 0);
    // Listen to ride data and update local list accordingly.
    rideDao.streamSummariesOfMonth(widget.firstDay).listen((update) {
      rides = update;
      calculateDistances();
      setState(() {});
    });
    super.initState();
  }

  int getNumberOfDays() {
    var firstDay = widget.firstDay;
    var isDecember = firstDay.month == 12;
    var lastDay = DateTime(isDecember ? firstDay.year + 1 : firstDay.year, (isDecember ? 0 : firstDay.month + 1), 0);
    return lastDay.day;
  }

  void calculateDistances() {
    for (int i = 0; i < numberOfDays; i++) {
      var ridesOnDay = rides.where((r) => r.startTime.day == i);
      if (ridesOnDay.isEmpty) continue;
      var distanceSum = ridesOnDay.map((r) => r.distanceMetres).reduce((a, b) => a + b) / 1000;
      if (distanceSum > 10) distanceSum = distanceSum.floorToDouble();
      distances[i] = distanceSum;
    }
    maxY = distances.max;
    if (maxY > 5 && maxY < 10) maxY = maxY.ceilToDouble();
    if (maxY > 10 && maxY < 50) maxY = 5 * (maxY / 5).ceilToDouble();
    if (maxY > 50) maxY = 10 * (maxY / 10).ceilToDouble();
  }

  List<BarChartGroupData> getBars(Color color) {
    return distances
        .mapIndexed((i, d) => RideStatisticsGraph.createBar(
              x: i,
              y: d,
              color: color,
              selected: selectedIndex == null ? null : (selectedIndex == i),
              width: 3,
            ))
        .toList();
  }

  Widget getTitlesX(double value, TitleMeta meta, {required TextStyle style}) {
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

  String getHeaderInfoText() {
    if (distances.isEmpty) {
      return '';
    } else if (selectedIndex == null) {
      return '${distances.reduce((a, b) => a + b).round()} km';
    } else {
      return '${distances[selectedIndex!] < 10 ? distances[selectedIndex!] : distances[selectedIndex!].round()} km';
    }
  }

  String getMonthString(int i) {
    if (i == 1) return 'Januar';
    if (i == 2) return 'Februar';
    if (i == 3) return 'März';
    if (i == 4) return 'April';
    if (i == 5) return 'Mai';
    if (i == 6) return 'Juni';
    if (i == 7) return 'Juli';
    if (i == 8) return 'August';
    if (i == 9) return 'September';
    if (i == 10) return 'Oktober';
    if (i == 11) return 'November';
    return 'Dezember';
  }

  @override
  Widget build(BuildContext context) {
    return RideStatisticsGraph(
      maxY: maxY > 0 ? maxY : 1,
      bars: getBars(Theme.of(context).colorScheme.primary),
      getTitlesX: (value, meta) => getTitlesX(value, meta, style: Theme.of(context).textTheme.labelMedium!),
      handleBarToucH: (int? index) => setState(() => selectedIndex = index),
      headerSubTitle: (selectedIndex == null ? '' : '$selectedIndex. ') + getMonthString(widget.firstDay.month),
      headerTitle: 'Monat',
      headerInfoText: getHeaderInfoText(),
    );
  }
}
