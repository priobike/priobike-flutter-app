import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/news/service.dart';
import 'package:priobike/news/views/article_list_item.dart';
import 'package:provider/provider.dart';

class NewsView extends StatefulWidget {
  const NewsView({Key? key}) : super(key: key);

  @override
  NewsViewState createState() => NewsViewState();
}

class NewsViewState extends State<NewsView> {
  /// The associated articles service, which is injected by the provider.
  late NewsService newsService;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('de');
  }

  @override
  void didChangeDependencies() {
    newsService = Provider.of<NewsService>(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Container(
          color: Theme.of(context).colorScheme.background,
          child: Fade(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 128),
                  Row(
                    children: [
                      Row(children: [
                        AppBackButton(icon: Icons.chevron_left, onPressed: () => Navigator.pop(context)),
                        const HSpace(),
                        SubHeader(text: "Neuigkeiten", context: context),
                      ]),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: !newsService.hasLoaded
                      ? SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : newsService.articles.isEmpty
                          ? const Center(
                              child: Text('Keine Neuigkeiten verfügbar.'),
                            )
                          : ListView(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              children: <Widget>[
                                for (int i = 0; i < newsService.articles.length; i++)
                                  ArticleListItem(
                                    article: newsService.articles[i],
                                    category: newsService.categories[newsService.articles[i].categoryId],
                                    wasRead: newsService.readArticles.contains(newsService.articles[i]),
                                    totalNumberOfArticles: newsService.articles.length,
                                    articleIndex: i
                                  )
                              ],
                            ),
                  ),
                  const SizedBox(height: 128),
                ],
              ),
            ),
          )
        ),
      ),
    );
  }
}
