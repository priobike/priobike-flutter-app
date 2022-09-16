import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:priobike/ride/views/button.dart';
import 'package:provider/provider.dart';

class MinimalDebugCyclingView extends StatefulWidget {
  const MinimalDebugCyclingView({Key? key}) : super(key: key);

  @override
  State<MinimalDebugCyclingView> createState() =>
      _MinimalDebugCyclingViewState();
}

class _MinimalDebugCyclingViewState extends State<MinimalDebugCyclingView> {
  late Ride app;

  @override
  Widget build(BuildContext context) {
    app = Provider.of<Ride>(context);
    if (app.currentRecommendation == null) return Container();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Small(text: app.currentRecommendation!.toJson(), context: context),
            const Spacer(),
            const SizedBox(
              width: double.infinity,
              child: CancelButton(),
            ),
          ],
        ),
      ),
    );
  }
}
