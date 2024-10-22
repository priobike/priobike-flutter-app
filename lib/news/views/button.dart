import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/main.dart';
import 'package:priobike/news/services/news.dart';

class NewsButton extends StatefulWidget {
  /// A callback that is fired when the button was pressed.
  final void Function() onPressed;

  const NewsButton({required this.onPressed, super.key});

  @override
  NewsButtonState createState() => NewsButtonState();
}

class NewsButtonState extends State<NewsButton> {
  /// The associated articles service, which is injected by the provider.
  late News news;

  /// The number of unread articles.
  int unread = 0;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    checkUnread();
  }

  /// Checks if the number of unread articles has changed and updates the state.
  void checkUnread() {
    final unread = news.articles.where((article) => !news.readArticles.contains(article)).length;
    if (unread != this.unread) {
      setState(
        () {
          this.unread = unread;
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    news = getIt<News>();
    news.addListener(update);
    checkUnread();
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
        SmallIconButtonSecondary(
          icon: Icons.notifications_rounded,
          color: Colors.white,
          splash: Theme.of(context).colorScheme.surfaceTint,
          fill: Colors.transparent,
          borderColor: Colors.white,
          withBorder: true,
          onPressed: widget.onPressed,
        ),
        if (unread > 0)
          Container(
            height: 18,
            width: 18,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: CI.radkulturYellow,
            ),
          ),
      ],
    );
  }
}
