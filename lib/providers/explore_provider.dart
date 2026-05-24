import 'package:flutter/material.dart';
import '../services/wikipedia_service.dart';

class ExploreProvider extends ChangeNotifier {
  String _busquedaActual = 'Objetivos de Desarrollo Sostenible';
  bool _isLoading = false;
  List<dynamic> _resultados = [];

  String get busquedaActual => _busquedaActual;
  bool get isLoading => _isLoading;
  List<dynamic> get resultados => _resultados;

  ExploreProvider() {
    buscar(_busquedaActual);
  }

  Future<void> buscar(String query) async {
    if (query.trim().isEmpty) return;

    _busquedaActual = query;
    _isLoading = true;
    notifyListeners();

    _resultados = await WikipediaService.buscarArticulos(_busquedaActual);

    _isLoading = false;
    notifyListeners();
  }
}
