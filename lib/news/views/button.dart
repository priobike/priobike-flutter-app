

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/news/service.dart';
import 'package:provider/provider.dart';

class NewsButton extends StatefulWidget {
  /// A callback that is fired when the button was pressed.
  final void Function() onPressed;

  const NewsButton({required this.onPressed, Key? key}) : super(key: key);

  @override 
  NewsButtonState createState() => NewsButtonState();
}

class NewsButtonState extends State<NewsButton> {
  /// The associated articles service, which is injected by the provider.
  late NewsService newsService;

  /// The number of unread articles.
  int unread = 0;

  @override
  void didChangeDependencies() {
    newsService = Provider.of<NewsService>(context);
    final unread = newsService.articles.where((article) => !newsService.readArticles.contains(article)).length;
    if (unread != this.unread) {
      setState(() {
        this.unread = unread;
      });
    }
    super.didChangeDependencies();
  }

  @override 
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        SmallIconButton(
          icon: Icons.notifications, 
          color: Theme.of(context).colorScheme.background, 
          splash: Colors.white,
          fill: const Color.fromARGB(50, 255, 255, 255),
          onPressed: widget.onPressed,
        ),
        if (unread > 0) Container(
          height: 18,
          width: 18,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
          ),
          child: Small(text: "$unread", color: Colors.white),
        ),
      ],
    );
  }
}