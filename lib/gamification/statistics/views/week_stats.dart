import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/ride_summary/ride_summary.dart';
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

  double maxY = 0;

  int? selectedIndex;

  @override
  void initState() {
    // Listen to ride data and update local list accordingly.
    rideDao.streamSummariesOfWeek(widget.startDay).listen((update) {
      rides = update;
      calculateDistances();
      setState(() {});
    });
    super.initState();
  }

  void calculateDistances() {
    for (int i = 0; i < 7; i++) {
      var weekDay = widget.startDay.add(Duration(days: i)).day;
      var ridesOnDay = rides.where((ride) => ride.startTime.day == weekDay);
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
            ))
        .toList();
  }

  Widget getTitlesX(double value, TitleMeta meta, {required TextStyle style}) {
    var today = DateTime.now();
    var todayIndex = today.difference(widget.startDay).inDays;
    String text = 'Mo';
    if (value == 1) text = 'Di';
    if (value == 2) text = 'Mi';
    if (value == 3) text = 'Do';
    if (value == 4) text = 'Fr';
    if (value == 5) text = 'Sa';
    if (value == 6) text = 'So';
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
    if (selectedIndex == null) {
      return '${distances.reduce((a, b) => a + b).round()} km';
    } else {
      return '${distances[selectedIndex!] < 10 ? distances[selectedIndex!].toStringAsFixed(1) : distances[selectedIndex!].round()} km';
    }
  }

  String getSubHeader() {
    var firstDay = DateFormat("dd.MM").format(widget.startDay);
    var lastDay = DateFormat("dd.MM").format(widget.startDay.add(const Duration(days: 6)));
    if (selectedIndex == null) {
      return '$firstDay - $lastDay';
    } else {
      return DateFormat("dd.MM").format(widget.startDay.add(Duration(days: selectedIndex!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RideStatisticsGraph(
      maxY: maxY > 0 ? maxY : 1,
      bars: getBars(Theme.of(context).colorScheme.primary),
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
