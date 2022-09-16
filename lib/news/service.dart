import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/news/models/article.dart';
import 'package:priobike/news/models/category.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class News with ChangeNotifier {
  var hasLoaded = false;

  /// The logger for this service.
  final log = Logger("News");

  /// List with all articles
  List<Article> articles = [];

  /// List with all articles that have been read by the user
  Set<Article> readArticles = {};

  /// Map with all categories
  Map<int, Category> categories = {};

  /// The HTTP client used to make requests to the backend.
  http.Client httpClient = http.Client();

  /// Reset the service to its initial state.
  Future<void> reset() async {
    hasLoaded = false;
    articles = [];
    readArticles = {};
    categories = {};
    notifyListeners();
  }

  /// Returns all available articles from the shared preferences or if not stored locally from the backend server.
  Future<void> getArticles(BuildContext context) async {
    if (hasLoaded) return;

    // Get articles that are already saved in the shared preferences on the device.
    List<Article> localSavedArticles = await _getStoredArticles(context);

    // If there are articles saved already in the shared preferences on the device
    // get the lastSyncDate for later usage eg when deciding whether the "Neu"-tag
    // should be shown on the article items in the list.
    DateTime? newLastSyncDate;
    if (localSavedArticles.isNotEmpty) {
      newLastSyncDate = localSavedArticles[0].pubDate;
    }

    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;
    final newsArticlesUrl = newLastSyncDate == null
        ? "https://$baseUrl/news-service/news/articles"
        : "https://$baseUrl/news-service/news/articles?from=${DateFormat('yyyy-MM-ddTH:mm:ss').format(newLastSyncDate)}Z";
    final newsArticlesEndpoint = Uri.parse(newsArticlesUrl);

    List<Article> articlesFromServer = [];

    // Catch the error if there is no connection to the internet.
    try {
      http.Response response = await httpClient.get(newsArticlesEndpoint);

      if (response.statusCode != 200) {
        final err = "News articles could not be fetched from endpoint $newsArticlesEndpoint: ${response.body}";
        log.e(err);
        ToastMessage.showError(err);
        throw Exception(err);
      }

      await json.decode(response.body).forEach((element) {
        final Article article = Article.fromJson(element);
        articlesFromServer.add(article);
      });
    } on SocketException catch (_) {
      log.i("Not connected to the internet");
    }

    articles = [...articlesFromServer, ...localSavedArticles];

    await _getCategories(context);

    await _storeArticles(context);

    readArticles = await _getStoredReadArticles(context);

    hasLoaded = true;
    notifyListeners();
  }

  /// Gets a all categories for the given [articles].
  Future<void> _getCategories(BuildContext context) async {
    for(final article in articles){
      if (article.categoryId != null && !categories.containsKey(article.categoryId)) await _getCategory(context, article.categoryId!);
    }
  }

  /// Gets single category given the [categoryId] from the shared preferences or if not stored locally from the backend server
  Future<void> _getCategory(BuildContext context, int categoryId) async {
    Category? category = await _getStoredCategory(context, categoryId);
    if (category != null) {
      if (!categories.containsKey(categoryId)) categories[categoryId] = category;
      return;
    }

    // If the category doesn't exist already in the shared preferences get it from backend server.
    final settings = Provider.of<Settings>(context, listen: false);
    final baseUrl = settings.backend.path;
    final newsCategoryUrl = "https://$baseUrl/news-service/news/category/${categoryId.toString()}";
    final newsCategoryEndpoint = Uri.parse(newsCategoryUrl);

    // Catch the error if there is no connection to the internet.
    try {
      http.Response response = await httpClient.get(newsCategoryEndpoint);

      if (response.statusCode != 200) {
        final err = "News category could not be fetched from endpoint $newsCategoryEndpoint: ${response.body}";
        log.e(err);
        ToastMessage.showError(err);
        throw Exception(err);
      }

      category = Category.fromJson(json.decode(response.body));

      if (!categories.containsKey(categoryId)) categories[categoryId] = category;

      await _storeCategory(context, category);
    } on SocketException catch (_) {
      log.i("Not connected to the internet");
    }
  }

  /// Store all articles in shared preferences.
  Future<void> _storeArticles(BuildContext context) async {
    if (articles.isEmpty) return;
    final storage = await SharedPreferences.getInstance();

    final backend = Provider.of<Settings>(context, listen: false).backend;

    final jsonStr = jsonEncode(articles.map((e) => e.toJson()).toList());
    if (backend == Backend.production) {
      await storage.setString("priobike.news.articles.production", jsonStr);
    } else if (backend == Backend.staging) {
      await storage.setString("priobike.news.articles.staging", jsonStr);
    }
  }

  /// Store category in shared preferences.
  Future<void> _storeCategory(BuildContext context, Category category) async {
    if (articles.isEmpty) return;
    final storage = await SharedPreferences.getInstance();

    final backend = Provider.of<Settings>(context, listen: false).backend;

    final String jsonStr = jsonEncode(category.toJson());
    if (backend == Backend.production) {
      await storage.setString("priobike.news.categories.production.${category.id}", jsonStr);
    } else if (backend == Backend.staging) {
      await storage.setString("priobike.news.categories.staging.${category.id}", jsonStr);
    }
  }

  /// Get all stored articles
  Future<List<Article>> _getStoredArticles(BuildContext context) async {
    final storage = await SharedPreferences.getInstance();

    final backend = Provider.of<Settings>(context, listen: false).backend;

    String? storedArticlesStr;

    if (backend == Backend.production) {
      storedArticlesStr = storage.getString("priobike.news.articles.production");
    } else if (backend == Backend.staging) {
      storedArticlesStr = storage.getString("priobike.news.articles.staging");
    }

    if (storedArticlesStr == null){
      return [];
    }

    List<Article> storedArticles = [];
    for (final articleMap in jsonDecode(storedArticlesStr)){
      storedArticles.add(Article.fromJson(articleMap));
    }

    return storedArticles;
  }

  /// Get stored category for given [categoryId]
  Future<Category?> _getStoredCategory(BuildContext context, int categoryId) async {
    final storage = await SharedPreferences.getInstance();

    final backend = Provider.of<Settings>(context, listen: false).backend;

    String? storedCategoryStr;

    if (backend == Backend.production) {
      storedCategoryStr = storage.getString("priobike.news.categories.production.$categoryId");
    } else if (backend == Backend.staging) {
      storedCategoryStr = storage.getString("priobike.news.categories.staging.$categoryId");
    }

    if (storedCategoryStr == null){
      return null;
    }

    return Category.fromJson(jsonDecode(storedCategoryStr));
  }

  /// Store all read articles in shared preferences.
  Future<void> storeReadArticles(Backend backend) async {
    if (readArticles.isEmpty) return;
    final storage = await SharedPreferences.getInstance();

    final jsonStr = jsonEncode(readArticles.map((e) => e.toJson()).toList());

    if (backend == Backend.production) {
      await storage.setString("priobike.news.read_articles.production", jsonStr);
    } else if (backend == Backend.staging) {
      await storage.setString("priobike.news.read_articles.staging", jsonStr);
    }
  }

  /// Get stored articles that were already read by the user.
  Future<Set<Article>> _getStoredReadArticles(BuildContext context) async {
    final storage = await SharedPreferences.getInstance();

    final backend = Provider.of<Settings>(context, listen: false).backend;

    String? storedReadArticlesStr;

    if (backend == Backend.production) {
      storedReadArticlesStr = storage.getString("priobike.news.read_articles.production");
    } else if (backend == Backend.staging) {
      storedReadArticlesStr = storage.getString("priobike.news.read_articles.staging");
    }

    if (storedReadArticlesStr == null){
      return {};
    }

    Set<Article> storedReadArticles = {};
    for (final articleMap in jsonDecode(storedReadArticlesStr)){
      storedReadArticles.add(Article.fromJson(articleMap));
    }

    return storedReadArticles;
  }

  /// Mark all articles as read.
  void markAllArticlesAsRead() {
    readArticles.addAll(articles);
    notifyListeners();
  }
}
