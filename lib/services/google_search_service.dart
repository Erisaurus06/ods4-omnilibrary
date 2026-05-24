import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleSearchService {
  // Nota: Estas llaves las obtienes gratis en Google Cloud Console
  static const String _apiKey = 'TU_API_KEY_AQUI';
  // El Search Engine ID configurado para buscar sitios académicos
  static const String _cx = 'TU_SEARCH_ENGINE_ID_AQUI';

  /// Realiza una búsqueda obligando a Google a retornar archivos PDF académicos
  static Future<List<dynamic>> buscarDocumentosConfiables(String query) async {
    if (query.trim().isEmpty) return [];

    // Forzamos al algoritmo a buscar documentos pdf
    final searchQuery = '$query filetype:pdf';
    final url = Uri.parse(
      'https://customsearch.googleapis.com/customsearch/v1?key=$_apiKey&cx=$_cx&q=${Uri.encodeComponent(searchQuery)}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['items'] ?? []; // Retorna la lista de URLs y descripciones
      }
    } catch (e) {
      print('Error en Google Academic Search: $e');
    }
    return [];
  }
}
