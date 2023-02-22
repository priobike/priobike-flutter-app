import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/news/services/news.dart';

class NewsButton extends StatefulWidget {
  /// A callback that is fired when the button was pressed.
  final void Function() onPressed;

  const NewsButton({required this.onPressed, Key? key}) : super(key: key);

  @override
  NewsButtonState createState() => NewsButtonState();
}

class NewsButtonState extends State<NewsButton> {
  /// The associated articles service, which is injected by the provider.
  late News news;

  /// The number of unread articles.
  int unread = 0;

  /// Called when a listener callback of a ChangeNotifier is fired.
  late VoidCallback update;

  @override
  void initState() {
    news = GetIt.instance.get<News>();
    update = () {
      final unread = news.articles.where((article) => !news.readArticles.contains(article)).length;
      if (unread != this.unread) {
        setState(
          () {
            this.unread = unread;
          },
        );
      }
    };
    news.addListener(update);

    super.initState();
  }

  @override
  void dispose() {
    news.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        SmallIconButton(
          icon: Icons.notifications_rounded,
          color: Colors.white,
          splash: Colors.white,
          fill: const Color.fromARGB(50, 255, 255, 255),
          onPressed: widget.onPressed,
        ),
        if (unread > 0)
          Container(
            height: 18,
            width: 18,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: CI.red,
            ),
            child: Small(text: "$unread", color: Colors.white, context: context),
          ),
      ],
    );
  }
}
