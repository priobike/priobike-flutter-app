import 'dart:developer';
import 'dart:math' as m;

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/database/database.dart';
import 'package:priobike/statistics/views/total.dart';

class GamificationHubView extends StatefulWidget {
  const GamificationHubView({Key? key}) : super(key: key);

  @override
  GamificationHubViewState createState() => GamificationHubViewState();
}

class GamificationHubViewState extends State<GamificationHubView> {
  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  List<TestObject> objects = [];

  @override
  void initState() {
    super.initState();
    AppDatabase.instance.testDao.streamAllObjects().listen((event) {
      setState(() {
        objects = event;
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
                const TotalStatisticsView(),
                const SmallVSpace(),
                generateTestObjectButton(),
                const SmallVSpace(),
                generateObjetList(),
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
            var test = TestObjectsCompanion.insert(number: m.Random().nextInt(999999999));
            var result = (await AppDatabase.instance.testDao.createObject(test))!;
            if (!mounted) return;
            showDialog(
                context: context,
                builder: (_) => AlertDialog(
                      title: const Text('Object Generated'),
                      content: Text("TestObject(id: ${result.id}, number: ${result.number})"),
                    ));
          },
          child: const Text("Generate"),
        ));
  }

  Widget generateObjetList() {
    return Column(
      children: objects
          .map(
            (o) => Container(
              color: Color((m.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () {
                  var obj = TestObject(id: o.id, number: m.Random().nextInt(999999999));
                  AppDatabase.instance.testDao.updateObject(obj);
                },
                onDoubleTap: () {
                  AppDatabase.instance.testDao.deleteObject(o);
                },
                onLongPress: () {
                  log("Start Stream");
                  AppDatabase.instance.testDao
                      .streamObjectByPrimaryKey(o.id)
                      .listen((result) => log("Object(${o.id}) Stream: ${(result?.number.toString()) ?? "Empty"}"));
                },
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text("id: ${o.id}"),
                    Text("number: ${o.number}"),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
