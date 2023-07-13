import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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
  var hasLoaded = false;

  /// The logger for this service.
  final log = Logger("News");

  /// List with all articles
  List<Article> articles = [];

  /// List with all articles that have been read by the user
  Set<Article> readArticles = {};

  /// Map with all categories
  Map<int, Category> categories = {};

  /// Reset the service to its initial state.
  Future<void> reset() async {
    hasLoaded = false;
    articles = [];
    readArticles = {};
    categories = {};
    notifyListeners();
  }

  /// Returns all available articles from the shared preferences or if not stored locally from the backend server.
  Future<void> getArticles() async {
    // Get articles that are already saved in the shared preferences on the device.
    List<Article> localSavedArticles = await _getStoredArticles();

    // If there are articles saved already in the shared preferences on the device
    // get the lastSyncDate for later usage eg when deciding whether the "Neu"-tag
    // should be shown on the article items in the list.
    DateTime? newLastSyncDate;
    if (localSavedArticles.isNotEmpty) {
      newLastSyncDate = localSavedArticles[0].pubDate;
    }

    final settings = getIt<Settings>();
    final baseUrl = settings.backend.path;
    final newsArticlesUrl = newLastSyncDate == null
        ? "https://$baseUrl/news-service/news/articles"
        : "https://$baseUrl/news-service/news/articles?from=${DateFormat('yyyy-MM-ddTH:mm:ss').format(newLastSyncDate)}Z";
    final newsArticlesEndpoint = Uri.parse(newsArticlesUrl);

    List<Article> articlesFromServer = [];

    // Catch the error if there is no connection to the internet.
    try {
      http.Response response = await Http.get(newsArticlesEndpoint).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        final err = "News articles could not be fetched from endpoint $newsArticlesEndpoint: ${response.body}";
        throw Exception(err);
      }

      await json.decode(response.body).forEach(
        (element) {
          final Article article = Article.fromJson(element);
          articlesFromServer.add(article);
        },
      );
    } catch (e) {
      final hint = "Failed to load articles: $e";
      log.e(hint);
    }

    articles = [...articlesFromServer, ...localSavedArticles];

    await _getCategories();

    await _storeArticles();

    readArticles = await _getStoredReadArticles();

    hasLoaded = true;
    notifyListeners();
  }

  /// Gets a all categories for the given [articles].
  Future<void> _getCategories() async {
    for (final article in articles) {
      if (article.categoryId != null && !categories.containsKey(article.categoryId)) {
        await _getCategory(article.categoryId!);
      }
    }
  }

  /// Gets single category given the [categoryId] from the shared preferences or if not stored locally from the backend server
  Future<void> _getCategory(int categoryId) async {
    Category? category = await _getStoredCategory(categoryId);
    if (category != null) {
      if (!categories.containsKey(categoryId)) {
        categories[categoryId] = category;
      }
      return;
    }

    // If the category doesn't exist already in the shared preferences get it from backend server.
    final settings = getIt<Settings>();
    final baseUrl = settings.backend.path;
    final newsCategoryUrl = "https://$baseUrl/news-service/news/category/${categoryId.toString()}";
    final newsCategoryEndpoint = Uri.parse(newsCategoryUrl);

    // Catch the error if there is no connection to the internet.
    try {
      http.Response response = await Http.get(newsCategoryEndpoint).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        final err = "News category could not be fetched from endpoint $newsCategoryEndpoint: ${response.body}";
        throw Exception(err);
      }

      category = Category.fromJson(json.decode(response.body));

      if (!categories.containsKey(categoryId)) {
        categories[categoryId] = category;
      }

      await _storeCategory(category);
    } catch (e) {
      final hint = "Failed to load category: $e";
      log.e(hint);
    }
  }

  /// Store all articles in shared preferences.
  Future<void> _storeArticles() async {
    if (articles.isEmpty) return;
    final storage = await SharedPreferences.getInstance();

    final backend = getIt<Settings>().backend;

    final jsonStr = jsonEncode(articles.map((e) => e.toJson()).toList());
    await storage.setString("priobike.news.articles.${backend.name}", jsonStr);
  }

  /// Store category in shared preferences.
  Future<void> _storeCategory(Category category) async {
    if (articles.isEmpty) return;
    final storage = await SharedPreferences.getInstance();

    final backend = getIt<Settings>().backend;

    final String jsonStr = jsonEncode(category.toJson());
    await storage.setString("priobike.news.categories.${backend.name}.${category.id}", jsonStr);
  }

  /// Get all stored articles
  Future<List<Article>> _getStoredArticles() async {
    final storage = await SharedPreferences.getInstance();

    final backend = getIt<Settings>().backend;

    final storedArticlesStr = storage.getString("priobike.news.articles.${backend.name}");

    if (storedArticlesStr == null) {
      return [];
    }

    List<Article> storedArticles = [];
    for (final articleMap in jsonDecode(storedArticlesStr)) {
      storedArticles.add(Article.fromJson(articleMap));
    }

    return storedArticles;
  }

  /// Get stored category for given [categoryId]
  Future<Category?> _getStoredCategory(int categoryId) async {
    final storage = await SharedPreferences.getInstance();

    final backend = getIt<Settings>().backend;

    final storedCategoryStr = storage.getString("priobike.news.categories.${backend.name}.$categoryId");

    if (storedCategoryStr == null) {
      return null;
    }

    return Category.fromJson(jsonDecode(storedCategoryStr));
  }

  /// Store all read articles in shared preferences.
  Future<void> _storeReadArticles() async {
    if (readArticles.isEmpty) return;
    final storage = await SharedPreferences.getInstance();

    final backend = getIt<Settings>().backend;

    final jsonStr = jsonEncode(readArticles.map((e) => e.toJson()).toList());

    await storage.setString("priobike.news.read_articles.${backend.name}", jsonStr);
  }

  /// Get stored articles that were already read by the user.
  Future<Set<Article>> _getStoredReadArticles() async {
    final storage = await SharedPreferences.getInstance();

    final backend = getIt<Settings>().backend;

    final storedReadArticlesStr = storage.getString("priobike.news.read_articles.${backend.name}");

    if (storedReadArticlesStr == null) {
      return {};
    }

    Set<Article> storedReadArticles = {};
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
