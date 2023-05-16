import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/wiki/detail.dart';
import 'package:priobike/wiki/models/article.dart';

class WikiCard extends StatefulWidget {
  const WikiCard({Key? key, required this.article, required this.imagePadding}) : super(key: key);

  /// The article of the WikiCard.
  final Article article;

  /// The bottom Padding applied to the image.
  final double imagePadding;

  @override
  WikiCardState createState() => WikiCardState();
}

class WikiCardState extends State<WikiCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 5, right: 5, bottom: 20),
      child: Tile(
        borderRadius: const BorderRadius.all(
          Radius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        fill: Theme.of(context).colorScheme.background,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => WikiDetailView(article: widget.article)));
        },
        content: Column(children: [
          Expanded(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(top: 10, right: 10, bottom: widget.imagePadding),
                    child: Image(
                      image: AssetImage(widget.article.image),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: BoldSubHeader(text: widget.article.title, context: context),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Small(
                              text: "${widget.article.subtitle} - ${widget.article.estimatedTime}",
                              color: Colors.grey,
                              context: context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 14,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ]),
      ),
    );
  }
}
