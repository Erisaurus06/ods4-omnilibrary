import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleBooksService {
  static String get _apiKey => dotenv.env['GOOGLE_API_KEY'] ?? '';

  /// Busca libros en el catálogo mundial de Google Play Books
  static Future<List<dynamic>> buscarLibros(String query) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.parse(
      'https://www.googleapis.com/books/v1/volumes?q=${Uri.encodeComponent(query)}&maxResults=15&key=$_apiKey',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['items'] ?? [];
      }
    } catch (e) {
      debugPrint('Error Google Books: $e');
    }
    return [];
  }
}
