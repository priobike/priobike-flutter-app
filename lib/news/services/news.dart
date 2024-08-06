import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import 'package:priobike/http.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/news/models/article.dart';
import 'package:priobike/news/models/category.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class News with ChangeNotifier {
  /// The bool that holds the state if the data was loaded at least once.
  bool hasLoaded = false;

  /// The bool that holds the state if an error occurred while loading the data.
  bool hadError = false;

  /// The logger for this service.
  final log = Logger("News");

  /// List with all articles
  List<Article> articles = [];

  /// List with all articles that have been read by the user
  HashSet<Article> readArticles = HashSet();

  /// Map with all categories
  Map<int, Category> categories = {};

  /// Reset the service to its initial state.
  Future<void> reset() async {
    hasLoaded = false;
    articles.clear();
    readArticles.clear();
    categories.clear();
    notifyListeners();
  }

  /// Returns all available articles from the shared preferences or if not stored locally from the backend server.
  Future<void> getArticles() async {
    final settings = getIt<Settings>();

    String baseUrl = settings.city.selectedBackend(false).path;

    final newsArticlesUrl = "https://$baseUrl/news-service/news/articles";
    final newsArticlesEndpoint = Uri.parse(newsArticlesUrl);

    List<Article> newArticles = [];

    // Catch the error if there is no connection to the internet.
    try {
      final response = await Http.get(newsArticlesEndpoint).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        final err = "News articles could not be fetched from endpoint $newsArticlesEndpoint: ${response.body}";
        throw Exception(err);
      }

      await json.decode(response.body).forEach(
        (element) {
          final Article article = Article.fromJson(element);
          newArticles.add(article);
        },
      );
      hadError = false;
    } catch (e, stacktrace) {
      final hint = "Failed to load articles from server: $e $stacktrace";
      log.e(hint);
      hadError = true;
    }

    articles = newArticles;

    await _getCategories();

    readArticles = await _getStoredReadArticles();

    hasLoaded = true;
    notifyListeners();
  }

  /// Gets a all categories for the given [articles].
  Future<void> _getCategories() async {
    for (final article in articles) {
      if (article.categoryId != null && !categories.containsKey(article.categoryId)) {
        await _fetchCategory(article.categoryId!);
      }
    }
  }

  /// Fetches single category given the [categoryId] from the backend server
  Future<void> _fetchCategory(int categoryId) async {
    final settings = getIt<Settings>();
    final baseUrl = settings.city.selectedBackend(false).path;
    final newsCategoryUrl = "https://$baseUrl/news-service/news/category/${categoryId.toString()}";
    final newsCategoryEndpoint = Uri.parse(newsCategoryUrl);

    // Catch the error if there is no connection to the internet.
    try {
      http.Response response = await Http.get(newsCategoryEndpoint).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        final err = "News category could not be fetched from endpoint $newsCategoryEndpoint: ${response.body}";
        throw Exception(err);
      }

      final category = Category.fromJson(json.decode(response.body));

      if (!categories.containsKey(categoryId)) {
        categories[categoryId] = category;
      }
    } catch (e) {
      final hint = "Failed to load category: $e";
      log.e(hint);
    }
  }

  /// Store all read articles in shared preferences.
  Future<void> _storeReadArticles() async {
    if (readArticles.isEmpty) return;
    final storage = await SharedPreferences.getInstance();

    final backend = getIt<Settings>().city.selectedBackend(false);

    final jsonStr = jsonEncode(readArticles.map((e) => e.toJson()).toList());

    await storage.setString("priobike.news.read_articles.${backend.name}", jsonStr);
  }

  /// Get stored articles that were already read by the user.
  Future<HashSet<Article>> _getStoredReadArticles() async {
    final storage = await SharedPreferences.getInstance();

    final backend = getIt<Settings>().city.selectedBackend(false);

    final storedReadArticlesStr = storage.getString("priobike.news.read_articles.${backend.name}");

    if (storedReadArticlesStr == null) {
      return HashSet();
    }

    HashSet<Article> storedReadArticles = HashSet();
    for (final articleMap in jsonDecode(storedReadArticlesStr)) {
      storedReadArticles.add(Article.fromJson(articleMap));
    }

    return storedReadArticles;
  }

  /// Mark all articles as read.
  void markAllArticlesAsRead() {
    // Check whether there are new articles that are not already marked as read and
    // stored in the shared preferences (not necessary for the readArticles set, but to
    // reduce unnecessary storing of the articles)
    final bool newUnreadArticles = !readArticles.containsAll(articles);
    if (newUnreadArticles) {
      readArticles.addAll(articles);
      _storeReadArticles();
      notifyListeners();
    }
  }
}
