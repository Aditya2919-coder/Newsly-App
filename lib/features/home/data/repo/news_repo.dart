import 'package:dio/dio.dart';

import '../model/news_model.dart';

class NewsRepository {
  NewsRepository()
    : _dio = Dio(
        BaseOptions(
          baseUrl: 'https://gnews.io/api/v4',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          responseType: ResponseType.json,
        ),
      );

  static const String _apiKey = "31d83f1836375c5f047edfbda7b6b3c1";
  static const int _pageSize = 10;
  final Dio _dio;

  bool get hasApiKey => _apiKey.isNotEmpty;

  Future<NewsPage> fetchTopHeadlines({required int page}) async {
    if (_apiKey.isEmpty) {
      throw const NewsApiException(
        'GNews API key was not provided at build time. Stop the app and run '
        'flutter run --dart-define="GNEWS_API_KEY=YOUR_API_KEY". '
        'A hot reload will not apply this value.',
      );
    }

    try {
      final response = await _dio.get<dynamic>(
        '/top-headlines',
        queryParameters: {
          'category': 'general',
          'country': 'in',
          'lang': 'en',
          'max': _pageSize,
          'page': page,
          'apikey': _apiKey,
        },
      );

      if (response.statusCode != 200) {
        throw NewsApiException(
          _readApiError(response.data, response.statusCode),
        );
      }

      return NewsPage.fromJson(response.data);
    } on NewsApiException {
      rethrow;
    } on FormatException catch (error) {
      throw NewsApiException('Invalid news response: ${error.message}');
    } on DioException catch (error) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        throw const NewsApiException(
          'The news request timed out. Check your connection and retry.',
          isNetworkError: true,
        );
      }
      if (error.type == DioExceptionType.connectionError ||
          error.response == null) {
        throw const NewsApiException(
          'Could not connect to the news service. Check your internet connection.',
          isNetworkError: true,
        );
      }

      throw NewsApiException(
        _readApiError(error.response?.data, error.response?.statusCode),
      );
    }
  }

  String _readApiError(dynamic data, int? statusCode) {
    if (data is Map) {
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors.join(', ');
      }
      final message = data['message'] ?? data['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    return 'News request failed${statusCode == null ? '.' : ' (HTTP $statusCode).'}';
  }
}

class NewsApiException implements Exception {
  const NewsApiException(this.message, {this.isNetworkError = false});

  final String message;
  final bool isNetworkError;

  @override
  String toString() => message;
}
