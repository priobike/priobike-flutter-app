import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/database/database.dart';
import 'package:priobike/common/database/model/ride_summary/ride_summary.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/statistics/views/total.dart';

class GamificationHubView extends StatefulWidget {
  const GamificationHubView({Key? key}) : super(key: key);

  @override
  GamificationHubViewState createState() => GamificationHubViewState();
}

class GamificationHubViewState extends State<GamificationHubView> {
  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  List<RideSummary> rides = [];

  RideSummaryDao rideDao = AppDatabase.instance.rideSummaryDao;

  @override
  void initState() {
    super.initState();
    rideDao.streamAllObjects().listen((update) {
      setState(() {
        rides = update;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    AppBackButton(onPressed: () => Navigator.pop(context)),
                    const HSpace(),
                    SubHeader(text: "Spiel", context: context),
                  ],
                ),
                const SmallVSpace(),
                TotalStatisticsView(
                  rideSummary: calculateTotalSummary(),
                ),
                const SmallVSpace(),
                generateRideList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget generateRideList() {
    return Column(
      children: rides
          .map(
            (ride) => Container(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onDoubleTap: () {
                  rideDao.deleteObject(ride);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text("id: ${ride.id},"),
                    Text("dis: ${ride.distance.toInt()},"),
                    Text("dur: ${ride.duration.toInt()},"),
                    Text("avg speed: ${ride.averageSpeed.toInt()},"),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  RideSummary? calculateTotalSummary() {
    if (rides.isEmpty) return null;
    return RideSummary(
      id: 0,
      distance: rides.map((r) => r.distance).reduce((a, b) => a + b),
      duration: rides.map((r) => r.duration).reduce((a, b) => a + b),
      elevationGain: rides.map((r) => r.elevationGain).reduce((a, b) => a + b),
      elevationLoss: rides.map((r) => r.elevationLoss).reduce((a, b) => a + b),
      averageSpeed: rides.map((r) => r.averageSpeed).reduce((a, b) => a + b) / rides.length,
    );
  }
}
