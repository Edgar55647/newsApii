import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'news_model.dart';
import 'news_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late final NewsService _service;
  final TextEditingController _controller = TextEditingController();

  List<NewsArticle> _articles = [];
  bool _isLoading = false;
  String? _error;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _service = NewsService();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final topic = _controller.text;

    if (topic.trim().isEmpty) {
      setState(() {
        _error = 'Ingresa un tema, por ejemplo: tecnología';
        _articles = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _hasSearched = true;
      _articles = [];
    });

    try {
      final result = await _service.fetchNews(topic);
      setState(() {
        _isLoading = false;
        _articles = result;
      });
    } on NewsException catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.message;
        _articles = [];
      });
    } on SocketException {
      setState(() {
        _isLoading = false;
        _error = 'No hay conexión a internet.';
        _articles = [];
      });
    } on TimeoutException {
      setState(() {
        _isLoading = false;
        _error =
            'La petición tardó demasiado. Intenta de nuevo más tarde.';
        _articles = [];
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _error = 'Ocurrió un error inesperado.';
        _articles = [];
      });
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Ingresa un tema (ej. tecnología, deportes, México) y presiona "Buscar noticias".',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_articles.isEmpty) {
      return const Center(
        child: Text(
          'Sin noticias para mostrar.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      itemCount: _articles.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final article = _articles[index];
        return ListTile(
          title: Text(article.title),
          subtitle: Text(
            '${article.sourceName}\n${article.description}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          isThreeLine: true,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Noticias (NewsAPI)'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        labelText: 'Tema',
                        hintText: 'Ej: tecnología, deportes, México',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _isLoading ? null : _search,
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }
}
