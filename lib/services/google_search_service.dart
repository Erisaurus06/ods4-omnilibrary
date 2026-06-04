import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleSearchService {
  // Extraemos las llaves de forma segura usando flutter_dotenv
  static String get _apiKey => dotenv.env['GOOGLE_API_KEY'] ?? '';
  static String get _cx => dotenv.env['GOOGLE_SEARCH_ENGINE_ID'] ?? '';

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

  /// Realiza una búsqueda exclusivamente en sitios confiables y académicos
  static Future<List<dynamic>> buscarArticulosConfiables(String query) async {
    if (query.trim().isEmpty) return [];

    // Filtramos usando operadores de búsqueda avanzados de Google para enciclopedias, diccionarios y dominios de alto nivel
    final searchQuery =
        '$query (site:rae.es OR site:concepto.de OR site:britannica.com OR site:humanidades.com OR site:ecured.cu OR site:citizendium.org OR site:wikidata.org OR site:medlineplus.gov OR site:eol.org OR site:worldhistory.org OR site:artehistoria.com OR site:elem.mx OR site:plato.stanford.edu OR site:vikidia.org OR site:harvard.edu OR site:mit.edu)';
    final url = Uri.parse(
      'https://customsearch.googleapis.com/customsearch/v1?key=$_apiKey&cx=$_cx&q=${Uri.encodeComponent(searchQuery)}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['items'] ?? [];
      }
    } catch (e) {
      print('Error en Google Reliable Search: $e');
    }
    return [];
  }

  /// Realiza una búsqueda web general libre, sin restricciones académicas.
  static Future<List<dynamic>> buscarWebGeneral(String query) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.parse(
      'https://customsearch.googleapis.com/customsearch/v1?key=$_apiKey&cx=$_cx&q=${Uri.encodeComponent(query)}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['items'] ?? [];
      }
    } catch (e) {
      print('Error en Google Web General: $e');
    }
    return [];
  }
}
