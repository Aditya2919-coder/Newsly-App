import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../data/model/news_model.dart';
import '../data/repo/news_repo.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({NewsRepository? repository, Box? storage})
    : _repository = repository ?? NewsRepository(),
      _storage = storage ?? Hive.box('auth_box') {
    unawaited(initialize());
  }

  final NewsRepository _repository;
  final Box _storage;
  final List<NewsArticle> _articles = [];
  final Map<String, NewsArticle> _bookmarks = {};

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingBookmarks = true;
  bool _requestInProgress = false;
  bool _initialized = false;
  bool _isNetworkError = false;
  int _currentPage = 0;
  int _totalArticles = 0;
  String? _errorMessage;
  String? _paginationError;
  String? _bookmarkError;

  List<NewsArticle> get articles => List.unmodifiable(_articles);
  List<NewsArticle> get bookmarks => List.unmodifiable(_bookmarks.values);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingBookmarks => _isLoadingBookmarks;
  String? get errorMessage => _errorMessage;
  String? get paginationError => _paginationError;
  String? get bookmarkError => _bookmarkError;
  bool get isNetworkError => _isNetworkError;

  bool get hasMore =>
      _currentPage * 10 < (_totalArticles < 1000 ? _totalArticles : 1000);

  bool isBookmarked(String url) => _bookmarks.containsKey(url);

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _loadBookmarks();
    await refresh();
  }

  Future<void> _loadBookmarks() async {
    try {
      final saved = _storage.get(LocalStorageKeyStrings.newsBookmarks);
      if (saved != null) {
        if (saved is! String) {
          throw const FormatException('Saved bookmarks are not valid text.');
        }
        final decoded = jsonDecode(saved);
        if (decoded is! List) {
          throw const FormatException('Saved bookmarks are not a list.');
        }
        for (final item in decoded) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('A saved bookmark is invalid.');
          }
          final article = NewsArticle.fromBookmarkJson(item);
          _bookmarks[article.url] = article;
        }
      }
    } on FormatException catch (error) {
      _bookmarkError = 'Could not read saved bookmarks: ${error.message}';
    } on TypeError {
      _bookmarkError = 'Saved bookmarks contain invalid data.';
    } catch (error) {
      _bookmarkError = 'Could not load saved bookmarks: $error';
    } finally {
      _isLoadingBookmarks = false;
      notifyListeners();
    }
  }

  Future<void> toggleBookmark(NewsArticle article) async {
    final existing = _bookmarks.remove(article.url);
    if (existing == null) {
      _bookmarks[article.url] = article;
    }
    _bookmarkError = null;
    notifyListeners();

    try {
      await _storage.put(
        LocalStorageKeyStrings.newsBookmarks,
        jsonEncode(
          _bookmarks.values.map((item) => item.toBookmarkJson()).toList(),
        ),
      );
    } catch (error) {
      if (existing == null) {
        _bookmarks.remove(article.url);
      } else {
        _bookmarks[article.url] = existing;
      }
      _bookmarkError = 'Could not save bookmark: $error';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> refresh() async {
    if (_requestInProgress) return;

    if (!_repository.hasApiKey) {
      _requestInProgress = false;
      _isLoading = false;
      _errorMessage = 'GNews API key is missing. Run the app with --dart-define="GNEWS_API_KEY=YOUR_API_KEY".';
      _paginationError = null;
      notifyListeners();
      return;
    }

    _requestInProgress = true;
    _isLoading = _articles.isEmpty;
    _errorMessage = null;
    _paginationError = null;
    _isNetworkError = false;
    notifyListeners();

    try {
      final result = await _repository.fetchTopHeadlines(page: 1);
      _articles
        ..clear()
        ..addAll(_uniqueArticles(result.articles));
      _currentPage = 1;
      _totalArticles = result.totalArticles;
    } catch (error) {
      _errorMessage = error.toString();
      _isNetworkError = error is NewsApiException && error.isNetworkError;
    } finally {
      _requestInProgress = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNextPage() async {
    if (_requestInProgress || !hasMore || _currentPage == 0) return;

    _requestInProgress = true;
    _isLoadingMore = true;
    _paginationError = null;
    _isNetworkError = false;
    notifyListeners();

    final nextPage = _currentPage + 1;
    try {
      final result = await _repository.fetchTopHeadlines(page: nextPage);
      final seenUrls = _articles.map((article) => article.url).toSet();
      for (final article in result.articles) {
        if (seenUrls.add(article.url)) {
          _articles.add(article);
        }
      }
      _currentPage = nextPage;
      _totalArticles = result.totalArticles;
    } catch (error) {
      _paginationError = error.toString();
      _isNetworkError = error is NewsApiException && error.isNetworkError;
    } finally {
      _requestInProgress = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  List<NewsArticle> _uniqueArticles(List<NewsArticle> articles) {
    final seenUrls = <String>{};
    return articles
        .where((article) => seenUrls.add(article.url))
        .toList(growable: false);
  }
}
