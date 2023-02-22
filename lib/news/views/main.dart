import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
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

  /// he singleton instance of our dependency injection service.
  final getIt = GetIt.instance;

  /// Called when a listener callback of a ChangeNotifier is fired.
  late VoidCallback update;

  @override
  void initState() {
    super.initState();
    update = () => setState(() {});
    news = getIt.get<News>();
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
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Fade(
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
    );
  }
}
