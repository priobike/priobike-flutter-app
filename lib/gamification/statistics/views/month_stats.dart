import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/ride_summary/ride_summary.dart';
import 'package:priobike/gamification/statistics/views/utils.dart';
import 'package:priobike/gamification/statistics/views/ride_graph.dart';

class MonthStatsView extends StatefulWidget {
  final int year;

  final int month;

  final String? headerTitle;

  final Function() tabHandler;

  const MonthStatsView({
    Key? key,
    required this.year,
    required this.tabHandler,
    required this.month,
    this.headerTitle,
  }) : super(key: key);

  @override
  State<MonthStatsView> createState() => _MonthStatsViewState();
}

class _MonthStatsViewState extends State<MonthStatsView> {
  /// Ride DAO required to load the rides from the db.
  final RideSummaryDao rideDao = AppDatabase.instance.rideSummaryDao;

  /// Loaded rides in a list.
  List<RideSummary> rides = [];

  late DateTime firstDay;

  late List<double> distances;

  int? selectedIndex;

  late int numberOfDays;

  @override
  void initState() {
    firstDay = DateTime(widget.year, widget.month, 1);
    numberOfDays = getNumberOfDays();
    distances = List.filled(numberOfDays, 0);
    // Listen to ride data and update local list accordingly.
    rideDao.streamSummariesOfMonth(firstDay).listen((update) {
      rides = update;
      calculateDistances();
      setState(() {});
    });
    super.initState();
  }

  int getNumberOfDays() {
    var isDecember = firstDay.month == 12;
    var lastDay = DateTime(isDecember ? firstDay.year + 1 : firstDay.year, (isDecember ? 0 : firstDay.month + 1), 0);
    return lastDay.day;
  }

  void calculateDistances() {
    for (int i = 0; i < numberOfDays; i++) {
      distances[i] = StatUtils.getDistanceSum(rides.where((r) => r.startTime.day == i).toList());
    }
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
      return '${StatUtils.getListSumStr(distances)} km';
    } else {
      return '${StatUtils.convertDoubleToStr(distances[selectedIndex!])} km';
    }
  }

  String getSubHeader() {
    return (selectedIndex == null ? '' : '$selectedIndex. ') + StatUtils.getMonthStr(firstDay.month);
  }

  @override
  Widget build(BuildContext context) {
    return RideStatisticsGraph(
      maxY: StatUtils.getFittingMax(distances.max),
      barColor: Theme.of(context).colorScheme.primary,
      barWidth: 5,
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
