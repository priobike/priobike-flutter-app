import 'package:flutter/material.dart';
import 'package:priobike/gamification/hub/views/cards/ride_statistics.dart';

class StatisticsView extends StatefulWidget {
  const StatisticsView({Key? key}) : super(key: key);

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> {
  @override
  Widget build(BuildContext context) {
    return RideStatisticsCard(openView: (view) {});
  }
}
