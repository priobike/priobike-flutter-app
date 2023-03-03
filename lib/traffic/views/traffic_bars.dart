import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ChartContainer extends StatelessWidget {
  final Color color;
  final String title;
  final Widget chart;

  const ChartContainer({
    Key? key,
    required this.title,
    required this.color,
    required this.chart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: chart,
    );
  }
}

class BarChartContent extends StatelessWidget {
  const BarChartContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<BarChartGroupData> barChartGroupData = [
      BarChartGroupData(
        x: 1,
        barsSpace: 0,
        barRods: [
          BarChartRodData(
            width: 50,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(1),
              topRight: Radius.circular(1),
            ),
            toY: 0.95,
            color: const Color(0xff43dde6),
          ),
        ],
      ),
      BarChartGroupData(
        x: 2,
        barRods: [
          BarChartRodData(
            width: 50,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(1),
              topRight: Radius.circular(1),
            ),
            toY: 0.96,
            color: const Color(0xff43dde6),
          ),
        ],
      ),
      BarChartGroupData(
        x: 3,
        barRods: [
          BarChartRodData(
            width: 50,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(1),
              topRight: Radius.circular(1),
            ),
            toY: 0.97,
            color: const Color(0xff43dde6),
          ),
        ],
      ),
      BarChartGroupData(
        x: 4,
        barRods: [
          BarChartRodData(
            width: 50,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(1),
              topRight: Radius.circular(1),
            ),
            toY: 0.98,
            color: const Color(0xff43dde6),
          ),
        ],
      ),
      BarChartGroupData(
        x: 5,
        barRods: [
          BarChartRodData(
            width: 50,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(1),
              topRight: Radius.circular(1),
            ),
            toY: 0.99,
            color: const Color(0xff43dde6),
          ),
        ],
      ),
      BarChartGroupData(
        x: 6,
        barRods: [
          BarChartRodData(
            width: 50,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(1),
              topRight: Radius.circular(1),
            ),
            toY: 1.0,
            color: const Color(0xff43dde6),
          ),
        ],
      ),
    ];

    return BarChart(
      BarChartData(
        barGroups: barChartGroupData,
        barTouchData: BarTouchData(
          enabled: false,
        ),
        maxY: 1,
        minY: 0.9,
        borderData: FlBorderData(
          border: Border.all(
            color: const Color(0xff37434d),
            width: 0,
          ),
          gridData: FlGridData(
            show: false,
          ),
        ),
        alignment: BarChartAlignment.spaceEvenly,
      ),
    );
  }
}
