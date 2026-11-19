/// A GNews headline mapped for the home feature.
class NewsArticle {
  const NewsArticle({
    required this.title,
    required this.url,
    required this.description,
    required this.sourceName,
    this.imageUrl,
    this.publishedAt,
  });

  final String title;
  final String url;
  final String description;
  final String sourceName;
  final String? imageUrl;
  final DateTime? publishedAt;

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    final title = json['title'];
    final url = json['url'];
    final parsedUrl = url is String ? Uri.tryParse(url) : null;
    if (title is! String || title.trim().isEmpty) {
      throw const FormatException('An article is missing its title.');
    }
    if (parsedUrl == null ||
        !{'http', 'https'}.contains(parsedUrl.scheme) ||
        parsedUrl.host.isEmpty) {
      throw const FormatException('An article is missing its URL.');
    }

    final source = json['source'];
    final sourceName = source is Map ? source['name'] : null;
    final image = json['image'];
    final published = json['publishedAt'];

    return NewsArticle(
      title: title.trim(),
      url: url,
      description: json['description'] is String
          ? json['description'] as String
          : '',
      sourceName: sourceName is String && sourceName.trim().isNotEmpty
          ? sourceName.trim()
          : 'Unknown source',
      imageUrl: image is String && image.trim().isNotEmpty ? image : null,
      publishedAt: published is String ? DateTime.tryParse(published) : null,
    );
  }

  factory NewsArticle.fromBookmarkJson(Map<String, dynamic> json) {
    final publishedAt = json['publishedAt'];

    return NewsArticle(
      title: json['title'] as String,
      url: json['url'] as String,
      description: json['description'] as String? ?? '',
      sourceName: json['sourceName'] as String? ?? 'Unknown source',
      imageUrl: json['imageUrl'] as String?,
      publishedAt: publishedAt is String ? DateTime.tryParse(publishedAt) : null,
    );
  }

  Map<String, dynamic> toBookmarkJson() => {
    'title': title,
    'url': url,
    'description': description,
    'sourceName': sourceName,
    'imageUrl': imageUrl,
    'publishedAt': publishedAt?.toIso8601String(),
  };

  String get publishedLabel {
    final date = publishedAt?.toLocal();
    if (date == null) return 'Date unavailable';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class NewsPage {
  const NewsPage({required this.articles, required this.totalArticles});

  final List<NewsArticle> articles;
  final int totalArticles;

  factory NewsPage.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('The news response is not a JSON object.');
    }

    final rawArticles = json['articles'];
    final rawTotal = json['totalArticles'];
    if (rawArticles is! List || rawTotal is! num) {
      throw const FormatException('The news response has an invalid format.');
    }

    return NewsPage(
      articles: rawArticles.map((article) {
        if (article is! Map<String, dynamic>) {
          throw const FormatException('The response contains an invalid article.');
        }
        return NewsArticle.fromJson(article);
      }).toList(growable: false),
      totalArticles: rawTotal.toInt(),
    );
  }
}
