import 'package:flutter/material.dart';
import '../services/wikipedia_service.dart';

class ExploreProvider extends ChangeNotifier {
  // Estado para Wikipedia
  String _busquedaActual = 'Objetivos de Desarrollo Sostenible';
  bool _isLoadingWikipedia = false;
  List<dynamic> _resultadosWikipedia = [];

  // Estado para Libros (Open Library)
  bool _isLoadingLibros = false;
  String _disciplinaActiva = 'Ciencias';
  List<dynamic> _librosActuales = [];

  // Getters para la interfaz
  String get busquedaActual => _busquedaActual;
  bool get isLoadingWikipedia => _isLoadingWikipedia;
  List<dynamic> get resultados => _resultadosWikipedia;

  bool get isLoadingLibros => _isLoadingLibros;
  String get disciplinaActiva => _disciplinaActiva;
  List<dynamic> get librosActuales => _librosActuales;

  ExploreProvider() {
    buscarWikipedia(_busquedaActual);
    cargarLibrosPorDisciplina(_disciplinaActiva);
  }

  // --- Lógica Wikipedia ---
  Future<void> buscarWikipedia(String query) async {
    if (query.trim().isEmpty) return;
    _busquedaActual = query;
    _isLoadingWikipedia = true;
    notifyListeners();

    _resultadosWikipedia = await WikipediaService.buscarArticulos(
      _busquedaActual,
    );

    _isLoadingWikipedia = false;
    notifyListeners();
  }

  // --- Lógica Open Library ---
  Future<void> cargarLibrosPorDisciplina(String disciplina) async {
    _isLoadingLibros = true;
    _disciplinaActiva = disciplina;
    notifyListeners();

    try {
      // final query =
      //     OpenLibraryService.rutasEducativas[disciplina] ?? disciplina;
      // final libros = await OpenLibraryService.buscarLibros(query);

      _librosActuales = []; // Placeholder as OpenLibraryService is missing
    } catch (e) {
      debugPrint('Error al conectar con la biblioteca global: $e');
      _librosActuales = [];
    }

    _isLoadingLibros = false;
    notifyListeners();
  }
}
