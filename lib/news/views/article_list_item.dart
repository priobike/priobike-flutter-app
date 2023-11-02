import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/news/models/article.dart';
import 'package:priobike/news/models/category.dart';

class ArticleListItem extends StatelessWidget {
  /// The article to display.
  final Article article;

  /// The optional category of the article.
  final Category? category;

  /// A boolean indicating whether the article was read.
  final bool wasRead;

  /// The total number of articles in the list.
  final int totalNumberOfArticles;

  /// The index of the article in the list.
  final int articleIndex;

  const ArticleListItem({
    required this.article,
    required this.category,
    required this.wasRead,
    required this.totalNumberOfArticles,
    required this.articleIndex,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show the divider below the last article item
    final bool divider = totalNumberOfArticles - 1 != articleIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (!wasRead)
              Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                decoration: BoxDecoration(
                  color: CI.red,
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: const Text("NEU", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            if (category != null)
              Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                decoration: BoxDecoration(
                  color: CI.blue,
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Text(category!.title, style: const TextStyle(fontSize: 16, color: Colors.white)),
              ),
          ],
        ),
        const SmallVSpace(),
        Small(
            text: '${DateFormat.E('de').format(article.pubDate)}. ${DateFormat.yMMMMd('de').format(article.pubDate)}',
            context: context),
        const SmallVSpace(),
        BoldSubHeader(text: article.title, context: context),
        const SmallVSpace(),
        Content(text: article.text, context: context),
        if (divider) const Padding(padding: EdgeInsets.symmetric(vertical: 24))
      ],
    );
  }
}
