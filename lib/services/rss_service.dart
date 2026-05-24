import 'package:http/http.dart' as http;
import 'package:dart_rss/dart_rss.dart';
import 'local_db_service.dart';

class RssService {
  /// Obtiene un flujo dinámico de noticias desde Google News basado en una categoría.
  /// Esto extrae información de los periódicos más importantes en tiempo real.
  static Future<RssFeed?> obtenerNoticiasPorCategoria(String categoria) async {
    // Formateamos la categoría para la URL (ej. "Videojuegos" o "Seguridad")
    final query = Uri.encodeComponent(categoria);

    // Endpoint de Google News RSS.
    // hl=es-419 (Español LatAm), gl=MX (Geolocalización México)
    final url = Uri.parse(
      'https://news.google.com/rss/search?q=$query&hl=es-419&gl=MX&ceid=MX:es-419',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          // Simulamos ser un navegador para evitar que Google News bloquee la petición
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36',
        },
      );
      if (response.statusCode == 200) {
        await LocalDbService.guardarNoticias(categoria, response.body);
        return RssFeed.parse(response.body);
      } else {
        print('Error en Google News RSS: Código HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Error obteniendo noticias de Google News: $e');
    }

    final cachedXml = LocalDbService.obtenerNoticias(categoria);
    if (cachedXml != null) {
      print('Cargando noticias desde caché local.');
      return RssFeed.parse(cachedXml);
    }

    return null;
  }
}
