import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/logging/logger.dart';

class LogsView extends StatefulWidget {
  const LogsView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => LogsViewState();
}

class LogsViewState extends State<LogsView> {
  final ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    Logger("Test").addToLog("Test asdiubnasiu ndaiun iausn aiun diuan aiusb diuab  oain dosn ");
    return SafeArea(
      child: Scaffold(
        body: Column(children: [
          Row(children: [
            AppBackButton(icon: Icons.chevron_left, onPressed: () => Navigator.pop(context)),
            const HSpace(),
            SubHeader(text: "Logs"),
          ]),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (var item in Logger.db)
                    Text(
                      item,
                      style: const TextStyle(
                        fontFamily: "monospace",
                        fontSize: 12,
                      ),
                    )
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
