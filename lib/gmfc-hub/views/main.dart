import 'dart:ffi';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/database/test_object.dart';
import 'package:priobike/database/test_repository.dart';
import 'package:priobike/statistics/views/total.dart';

class GamificationHubView extends StatefulWidget {
  const GamificationHubView({Key? key}) : super(key: key);

  @override
  GamificationHubViewState createState() => GamificationHubViewState();
}

class GamificationHubViewState extends State<GamificationHubView> {
  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  final TestRepository repository = TestRepository();

  @override
  void initState() {
    super.initState();
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
                const TotalStatisticsView(),
                const SmallVSpace(),
                generateTestObjectButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget generateTestObjectButton() {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: TextButton(
          onPressed: () async {
            var test = TestObject(Random().nextInt(100000000));
            test = await repository.create(test);
            if (!mounted) return;
            showDialog(
                context: context,
                builder: (_) => AlertDialog(
                      title: const Text('Object Generated'),
                      content: Text("TestObject(id: ${test.id}, number: ${test.number})"),
                    ));
          },
          child: const Text("Generate"),
        ));
  }
}
