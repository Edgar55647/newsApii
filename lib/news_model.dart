class NewsArticle {
  final String title;
  final String description;
  final String sourceName;
  final String? url;
  final DateTime? publishedAt;

  NewsArticle({
    required this.title,
    required this.description,
    required this.sourceName,
    required this.url,
    required this.publishedAt,
  });

  factory NewsArticle.fromJson(
    Map<String, dynamic> json, {
    String Function(String)? sanitizer,
  }) {
    final sanitize = sanitizer ?? (String v) => v;

    final source = (json['source'] as Map<String, dynamic>?) ?? {};
    final rawTitle = (json['title'] ?? 'Sin título').toString();
    final rawDescription =
        (json['description'] ?? 'Sin descripción').toString();
    final rawSourceName =
        (source['name'] ?? 'Fuente desconocida').toString();

    DateTime? published;
    final publishedRaw = json['publishedAt'];
    if (publishedRaw is String && publishedRaw.isNotEmpty) {
      try {
        published = DateTime.tryParse(publishedRaw);
      } catch (_) {
        published = null;
      }
    }

    return NewsArticle(
      title: sanitize(rawTitle),
      description: sanitize(rawDescription),
      sourceName: sanitize(rawSourceName),
      url: json['url']?.toString(),
      publishedAt: published,
    );
  }
}
