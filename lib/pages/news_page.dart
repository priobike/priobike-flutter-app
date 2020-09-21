import 'package:bikenow/config/palette.dart';
import 'package:flutter/material.dart';

class NewsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _NewsPageState();
  }
}

class _NewsPageState extends State<NewsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black.withOpacity(0),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            color: Palette.button,
            width: double.infinity,
            height: 310,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "BikeNow weiterhin im Testlauf",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Spacer(),
                  Text(
                    "20. September 2020",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                   Spacer(),
                  Text(
                    "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
