import 'package:priobike/config/priobike_theme.dart';
import 'package:priobike/config/logger.dart';
import 'package:flutter/material.dart';

class LogPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _LogPageState();
  }
}

class _LogPageState extends State<LogPage> {
  ScrollController _scrollController = new ScrollController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: PrioBikeTheme.background,
        appBar: AppBar(
          title: Text("Log"),
          elevation: PrioBikeTheme.buttonElevation,
          backgroundColor: PrioBikeTheme.background,
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.arrow_upward,
                color: Colors.white70,
              ),
              onPressed: () => _scrollController.jumpTo(
                0.0,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.arrow_downward,
                color: Colors.white70,
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
                  style: TextStyle(
                    color: Colors.white,
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
