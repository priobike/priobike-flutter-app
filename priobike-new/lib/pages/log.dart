import 'package:priobike/utils/logger.dart';
import 'package:flutter/material.dart';

class LogPage extends StatefulWidget {
  const LogPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LogPageState();
  }
}

class _LogPageState extends State<LogPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("PrioBike: LogPage"),
          actions: <Widget>[
            IconButton(
              icon: const Icon(
                Icons.arrow_upward,
              ),
              onPressed: () => _scrollController.jumpTo(
                0.0,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.arrow_downward,
              ),
              onPressed: () => _scrollController.jumpTo(
                _scrollController.position.maxScrollExtent,
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            controller: _scrollController,
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
    );
  }
}
