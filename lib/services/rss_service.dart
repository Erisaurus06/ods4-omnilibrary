import 'package:http/http.dart' as http;
import 'package:dart_rss/dart_rss.dart';

class RssService {
  static Future<RssFeed?> obtenerNoticias() async {
    try {
      final url = Uri.parse(
        'https://feeds.elpais.com/mrss-s/pages/ep/site/elpais.com/seccion/tecnologia/portada',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Parseamos la respuesta usando la librería moderna dart_rss
        return RssFeed.parse(response.body);
      } else {
        print('Error en el servidor: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Ocurrió un error al procesar el RSS: $e');
      return null;
    }
  }
}
