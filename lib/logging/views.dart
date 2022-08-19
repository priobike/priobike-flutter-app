import 'package:flutter/material.dart';
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
    return Scaffold(body: SafeArea(
      child: Scaffold(
        body: Padding(
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
      ),
    ));
  }
}
