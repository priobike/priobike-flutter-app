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
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text("Lorem Ipsum"),
                subtitle: Text(
                    "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore."),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text("Lorem Ipsum"),
                subtitle: Text(
                    "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore."),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text("Lorem Ipsum"),
                subtitle: Text(
                    "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore."),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text("Lorem Ipsum"),
                subtitle: Text(
                    "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore."),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text("Lorem Ipsum"),
                subtitle: Text(
                    "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore."),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text("Lorem Ipsum"),
                subtitle: Text(
                    "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore."),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text("Lorem Ipsum"),
                subtitle: Text(
                    "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore."),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text("Lorem Ipsum"),
                subtitle: Text(
                    "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore."),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
