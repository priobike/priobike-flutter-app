import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/news/services/news.dart';
import 'package:priobike/news/views/article_list_item.dart';

class NewsView extends StatefulWidget {
  const NewsView({Key? key}) : super(key: key);

  @override
  NewsViewState createState() => NewsViewState();
}

class NewsViewState extends State<NewsView> {
  /// The associated articles service, which is injected by the provider.
  late News news;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();
    news = getIt<News>();
    news.addListener(update);
    initializeDateFormatting('de');
  }

  @override
  void dispose() {
    news.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(
              systemNavigationBarColor: Theme.of(context).colorScheme.background,
              systemNavigationBarIconBrightness: Brightness.light,
              statusBarIconBrightness: Brightness.light,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              systemNavigationBarColor: Theme.of(context).colorScheme.background,
              systemNavigationBarIconBrightness: Brightness.dark,
              statusBarIconBrightness: Brightness.dark,
            ),
      child: Scaffold(
        body: Fade(
          child: RefreshIndicator(
            edgeOffset: 64 + MediaQuery.of(context).padding.top,
            color: Colors.white,
            backgroundColor: Theme.of(context).colorScheme.primary,
            displacement: 42,
            onRefresh: () async {
              HapticFeedback.lightImpact();
              await news.getArticles();
              // Wait for one more second, otherwise the user will get impatient.
              await Future.delayed(
                const Duration(seconds: 1),
              );
              HapticFeedback.lightImpact();
            },
            child: SingleChildScrollView(
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Row(
                          children: [
                            AppBackButton(onPressed: () => Navigator.pop(context)),
                            const HSpace(),
                            SubHeader(text: "Neuigkeiten", context: context),
                          ],
                        ),
                      ],
                    ),
                    const SmallVSpace(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: !news.hasLoaded
                          ? SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : news.articles.isEmpty
                              ? const Center(
                                  child: Text('Keine Neuigkeiten verfügbar.'),
                                )
                              : ListView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  children: <Widget>[
                                    for (int i = 0; i < news.articles.length; i++)
                                      ArticleListItem(
                                          article: news.articles[i],
                                          category: news.categories[news.articles[i].categoryId],
                                          wasRead: news.readArticles.contains(news.articles[i]),
                                          totalNumberOfArticles: news.articles.length,
                                          articleIndex: i)
                                  ],
                                ),
                    ),
                    const SizedBox(height: 128),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
