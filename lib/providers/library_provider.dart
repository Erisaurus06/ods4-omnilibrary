import 'package:flutter/material.dart';
import '../services/local_db_service.dart';
import '../services/storage_service.dart';

class LibraryProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _documentos = [];
  String _etiquetaActiva = 'Todo';
  final StorageService _storageService = StorageService();

  List<Map<String, dynamic>> get documentos {
    if (_etiquetaActiva == 'Todo') {
      return _documentos;
    }
    return _documentos
        .where((doc) => doc['etiqueta'] == _etiquetaActiva)
        .toList();
  }

  List<String> get etiquetasDisponibles {
    final etiquetas = _documentos
        .map((e) => e['etiqueta'] as String?)
        .where((e) => e != null && e.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    etiquetas.insert(0, 'Todo');
    return etiquetas;
  }

  String get etiquetaActiva => _etiquetaActiva;

  LibraryProvider() {
    cargarBiblioteca();
  }

  void setEtiquetaActiva(String etiqueta) {
    _etiquetaActiva = etiqueta;
    notifyListeners();
  }

  void cargarBiblioteca() {
    final docsDB = LocalDbService.obtenerDocumentos();
    if (docsDB.isEmpty) {
      final datosIniciales = [
        {
          'titulo': 'Guía de Flutter (PDF Demo)',
          'descargado': true,
          'esPdf': true,
          'esEpub': false,
          'path':
              'https://cdn.syncfusion.com/content/PDFViewer/flutter-succinctly.pdf',
          'etiqueta': 'Tecnología',
        },
        {
          'titulo': 'Diccionario Filosófico',
          'descargado': false,
          'esPdf': true,
          'esEpub': false,
          'path': null,
          'url':
              'https://cdn.syncfusion.com/content/PDFViewer/flutter-succinctly.pdf',
          'etiqueta': 'Filosofía',
        },
        {
          'titulo': 'El Arte de la Guerra (ePub)',
          'descargado': true,
          'esPdf': false,
          'esEpub': true,
          'path': 'ruta_falsa.epub',
          'etiqueta': 'Historia',
        },
      ];
      for (var doc in datosIniciales) {
        LocalDbService.guardarDocumento(doc);
      }
      _documentos = datosIniciales;
    } else {
      _documentos = docsDB;
    }
    notifyListeners();
  }

  Future<void> agregarDocumento(Map<String, dynamic> doc) async {
    await LocalDbService.guardarDocumento(doc);
    _documentos.insert(0, doc);
    notifyListeners();
  }

  Future<void> descargarDocumento(Map<String, dynamic> doc) async {
    final realIndex = _documentos.indexWhere(
      (element) =>
          element['titulo'] == doc['titulo'] && element['url'] == doc['url'],
    );
    if (realIndex == -1) return;

    _documentos[realIndex]['descargando'] = true;
    notifyListeners();

    final newPath = await _storageService.downloadFileSilently(
      doc['url'],
      '${doc['titulo'].replaceAll(' ', '_')}.pdf',
    );

    _documentos[realIndex]['descargando'] = false;
    if (newPath != null) {
      _documentos[realIndex]['descargado'] = true;
      _documentos[realIndex]['path'] = newPath;
      await LocalDbService.actualizarDocumento(
        realIndex,
        _documentos[realIndex],
      );
    }
    notifyListeners();
  }
}
