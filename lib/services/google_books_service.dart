import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleBooksService {
  /// Busca libros en el catálogo mundial de Google Play Books
  static Future<List<dynamic>> buscarLibros(String query) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.parse(
      'https://www.googleapis.com/books/v1/volumes?q=${Uri.encodeComponent(query)}&maxResults=15',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['items'] ?? [];
      }
    } catch (e) {
      print('Error Google Books: $e');
    }
    return [];
  }
}
