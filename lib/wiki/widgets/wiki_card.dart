import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/wiki/detail.dart';
import 'package:priobike/wiki/models/article.dart';

class WikiCard extends StatefulWidget {
  const WikiCard({super.key, required this.article});

  /// The article of the WikiCard.
  final Article article;

  @override
  WikiCardState createState() => WikiCardState();
}

class WikiCardState extends State<WikiCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Tile(
        borderRadius: const BorderRadius.all(
          Radius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        fill: Theme.of(context).colorScheme.surfaceVariant,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => WikiDetailView(article: widget.article)));
        },
        content: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BoldSubHeader(text: widget.article.title, context: context, textAlign: TextAlign.left),
                    Small(
                      text: "${widget.article.subtitle} - ${widget.article.estimatedTime}",
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
                      context: context,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 64,
                height: 64,
                child: Image(image: AssetImage(widget.article.image), fit: BoxFit.cover),
              ),
            ]),
            const SizedBox(height: 16),
            Container(
              height: 8,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(4)),
                color: CI.radkulturRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
