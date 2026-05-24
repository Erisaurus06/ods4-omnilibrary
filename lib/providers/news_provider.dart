import 'package:flutter/material.dart';
import 'package:dart_rss/dart_rss.dart';
import '../services/rss_service.dart';
import '../services/news_filter_service.dart';

class NewsProvider extends ChangeNotifier {
  RssFeed? _feed;
  bool _isLoading = false;
  String _categoriaSeleccionada = 'Videojuegos';
  final NewsFilterService _newsFilterService = NewsFilterService();

  RssFeed? get feed => _feed;
  bool get isLoading => _isLoading;
  String get categoriaSeleccionada => _categoriaSeleccionada;
  NewsFilterService get newsFilterService => _newsFilterService;

  NewsProvider() {
    cargarNoticias();
  }

  void setCategoria(String categoria) {
    _categoriaSeleccionada = categoria;
    cargarNoticias();
  }

  Future<void> cargarNoticias() async {
    _isLoading = true;
    notifyListeners();

    _feed = await RssService.obtenerNoticiasPorCategoria(
      _categoriaSeleccionada,
    );

    _isLoading = false;
    notifyListeners();
  }
}
