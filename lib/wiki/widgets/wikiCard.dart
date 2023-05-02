import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';

class WikiCard extends StatefulWidget {
  const WikiCard({Key? key, required this.title, required this.subTitle})
      : super(key: key);

  /// The title of the WikiCard.
  final String title;

  /// The SubTitle of the WikiCard.
  final String subTitle;


  @override
  WikiCardState createState() => WikiCardState();
}

class WikiCardState extends State<WikiCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Tile(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        fill: Theme
            .of(context)
            .colorScheme
            .background,
        onPressed: () {
          // TODO implement detail screen.
        },
        content: Container(
          color: Colors.blue,
          child: Content(context: context, text: widget.title),
        ),
      ),
    );
  }
}
