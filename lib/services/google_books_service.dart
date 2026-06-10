import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';

class GoogleBooksService {
  static String get _apiKey => dotenv.env['GOOGLE_API_KEY'] ?? '';

  /// Busca libros en el catálogo mundial de Google Play Books.
  /// Si [soloGratis] es true, filtra únicamente los libros gratuitos (ePub o PDF).
  static Future<List<dynamic>> buscarLibros(
    String query, {
    bool soloGratis = true,
  }) async {
    if (query.trim().isEmpty) return [];

    String baseUrl =
        'https://www.googleapis.com/books/v1/volumes?q=${Uri.encodeComponent(query)}&maxResults=20';

    if (soloGratis) {
      baseUrl += '&filter=free-ebooks';
    }

    if (_apiKey.isNotEmpty) {
      baseUrl += '&key=$_apiKey';
    }

    final url = Uri.parse(baseUrl);

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['items'] ?? [];
      } else {
        debugPrint('Error de servidor Google Books: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error Google Books: $e');
    }
    return [];
  }

  /// Extrae el link de descarga directo del ePub o PDF si está disponible
  static String? obtenerLinkDescarga(Map<String, dynamic> bookItem) {
    final accessInfo = bookItem['accessInfo'];
    if (accessInfo == null) return null;

    if (accessInfo['epub'] != null &&
        accessInfo['epub']['isAvailable'] == true &&
        accessInfo['epub']['downloadLink'] != null) {
      return accessInfo['epub']['downloadLink'];
    }
    if (accessInfo['pdf'] != null &&
        accessInfo['pdf']['isAvailable'] == true &&
        accessInfo['pdf']['downloadLink'] != null) {
      return accessInfo['pdf']['downloadLink'];
    }
    return null;
  }

  /// Descarga un libro desde una URL y lo guarda de forma segura en el almacenamiento local.
  /// Retorna la ruta absoluta del archivo descargado (path) para ser usado en el lector offline.
  static Future<String?> descargarLibro(
    String downloadUrl,
    String tituloLibro,
    bool isPdf,
  ) async {
    try {
      // Hacemos la petición para obtener los bytes del archivo
      final response = await http
          .get(Uri.parse(downloadUrl))
          .timeout(const Duration(minutes: 2));

      if (response.statusCode == 200) {
        // Limpiamos el título para que sea un nombre de archivo válido
        final safeName = tituloLibro
            .replaceAll(RegExp(r'[^\w\s]+'), '')
            .replaceAll(' ', '_');
        final extension = isPdf ? '.pdf' : '.epub';
        final fileName =
            '${safeName}_${DateTime.now().millisecondsSinceEpoch}$extension';

        // Obtenemos el directorio interno seguro de la app
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';

        // Guardamos los bytes en el dispositivo
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        return filePath;
      } else {
        debugPrint('Error HTTP al descargar libro: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Excepción al descargar el libro: $e');
    }
    return null;
  }
}
