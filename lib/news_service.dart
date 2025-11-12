import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'news_model.dart';

class NewsException implements Exception {
  NewsException(this.message);
  final String message;

  @override
  String toString() => message;
}

class NewsService {
  NewsService({
    http.Client? client,
    Duration? timeout,
  })  : _client = client ?? http.Client(),
        timeout = timeout ?? const Duration(seconds: 8),
        _apiKey = dotenv.env['API_KEY_NEWSAPI'] ?? '' {
    if (_apiKey.isEmpty) {
      throw StateError(
        'API_KEY_NEWSAPI no está configurada en .env',
      );
    }
  }

  final http.Client _client;
  final String _apiKey;
  final Duration timeout;

  // Cache defensiva (búsqueda -> lista de noticias)
  final Map<String, List<NewsArticle>> _cache = {};

  String _sanitizeQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('El tema no puede estar vacío');
    }

    // Solo letras, números básicos, espacios y algunos signos
    final sanitized = trimmed.replaceAll(
      RegExp(r'[^a-zA-Z0-9áéíóúÁÉÍÓÚñÑ\s\-\_,\.]'),
      '',
    );

    if (sanitized.isEmpty) {
      throw ArgumentError('El tema contiene caracteres inválidos');
    }

    return sanitized;
  }

  String _sanitizeText(String value) {
    // Quita caracteres de control no imprimibles
    return value.replaceAll(RegExp(r'[\x00-\x1F]'), '');
  }

  Future<List<NewsArticle>> fetchNews(String topic) async {
    final sanitizedTopic = _sanitizeQuery(topic);

    final uri = Uri.https(
      'newsapi.org',
      '/v2/everything',
      {
        'q': sanitizedTopic,
        'language': 'es',
        'pageSize': '20',
        'sortBy': 'publishedAt',
      },
    );

    const maxRetries = 3;
    var attempt = 0;

    while (true) {
      try {
        final resp = await _client
            .get(
              uri,
              headers: {
                'X-Api-Key': _apiKey, // NewsAPI usa header, no query param
              },
            )
            .timeout(timeout);

        if (resp.statusCode == 200) {
          final jsonMap =
              jsonDecode(resp.body) as Map<String, dynamic>;

          if (jsonMap['status'] != 'ok') {
            final code = jsonMap['code']?.toString() ?? 'desconocido';
            final msg = jsonMap['message']?.toString() ??
                'Error de NewsAPI ($code)';
            throw NewsException(msg);
          }

          final articlesJson =
              (jsonMap['articles'] as List<dynamic>? ?? []);
          final articles = articlesJson
              .map(
                (e) => NewsArticle.fromJson(
                  e as Map<String, dynamic>,
                  sanitizer: _sanitizeText,
                ),
              )
              .toList();

          if (articles.isEmpty) {
            throw NewsException(
              'No se encontraron noticias para ese tema.',
            );
          }

          _cache[sanitizedTopic.toLowerCase()] = articles;
          return articles;
        } else if (resp.statusCode == 401) {
          throw NewsException(
            'API key inválida o no autorizada (401).',
          );
        } else if (resp.statusCode == 429) {
          // Rate limit -> usar cache si hay
          final cached =
              _cache[sanitizedTopic.toLowerCase()];
          if (cached != null) return cached;

          throw NewsException(
            'Límite de peticiones excedido (429). Intenta más tarde.',
          );
        } else {
          throw NewsException(
            'Error inesperado del servidor (${resp.statusCode}).',
          );
        }
      } on TimeoutException {
        attempt++;
        if (attempt >= maxRetries) {
          final cached =
              _cache[sanitizedTopic.toLowerCase()];
          if (cached != null) return cached;

          throw NewsException(
            'Tiempo de espera agotado. Verifica tu conexión.',
          );
        }

        // Retry exponencial simple: 0.4s, 1.6s, 3.6s...
        final backoffMs = 400 * attempt * attempt;
        await Future.delayed(
          Duration(milliseconds: backoffMs),
        );
      } on SocketException {
        // Sin internet -> cache defensiva
        final cached = _cache[sanitizedTopic.toLowerCase()];
        if (cached != null) return cached;

        rethrow;
      }
    }
  }
}
