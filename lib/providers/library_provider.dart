import 'package:flutter/material.dart';
import '../services/local_db_service.dart';
import '../services/supabase_service.dart';

class LibraryProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _libros = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get libros => _libros;
  bool get isLoading => _isLoading;

  LibraryProvider() {
    cargarLibrosLocales();
  }

  // 1. Cargar desde Hive (Offline First)
  void cargarLibrosLocales() {
    _libros = LocalDbService.obtenerDocumentos();
    notifyListeners();
  }

  // 2. Guardar Libro y Sincronizar a Supabase
  Future<void> agregarLibro(Map<String, dynamic> libro) async {
    _isLoading = true;
    notifyListeners();

    // Guardar localmente (Hive)
    await LocalDbService.guardarDocumento(libro);

    // Sincronizar con Supabase (si el usuario inició sesión)
    final user = SupabaseService.client.auth.currentUser;
    if (user != null) {
      try {
        await SupabaseService.client.from('biblioteca').insert({
          'user_id': user.id,
          'titulo': libro['titulo'],
          'path': libro['path'],
          'es_pdf': libro['esPdf'],
        });
      } catch (e) {
        print("Error sincronizando a la nube: $e");
      }
    }

    _libros = LocalDbService.obtenerDocumentos();
    _isLoading = false;
    notifyListeners();
  }
}
