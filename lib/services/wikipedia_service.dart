import 'dart:convert';
import 'package:http/http.dart' as http;

class WikipediaService {
  // Función principal para buscar en la API de Wikipedia en español
  static Future<List<dynamic>> buscarArticulos(String busqueda) async {
    // Si la búsqueda está vacía, devolvemos una lista vacía para evitar errores
    if (busqueda.trim().isEmpty) return [];

    // Formateamos la búsqueda para que la URL sea válida (ej. "Guerra Fría" -> "Guerra%20Fr%C3%ADa")
    final String busquedaFormateada = Uri.encodeComponent(busqueda);

    // URL oficial de la API de Wikipedia
    final url = Uri.parse(
      'https://es.wikipedia.org/w/api.php?action=query&list=search&srsearch=$busquedaFormateada&utf8=&format=json',
    );

    try {
      // Hacemos la petición a internet
      final response = await http.get(url);

      // Código 200 significa que la conexión fue exitosa
      if (response.statusCode == 200) {
        // Decodificamos el JSON que nos manda Wikipedia
        final data = json.decode(response.body);

        // Retornamos únicamente la lista de resultados
        List<dynamic> resultados = data['query']['search'] as List<dynamic>;

        // Limpiamos las etiquetas HTML del snippet para una mejor lectura
        for (var i = 0; i < resultados.length; i++) {
          String snippet = resultados[i]['snippet'] ?? '';
          resultados[i]['snippet'] = snippet.replaceAll(RegExp(r'<[^>]*>'), '');
        }

        return resultados;
      } else {
        print('Error del servidor: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      // Si no hay internet o falla algo, atrapamos el error aquí para que la app no se cierre
      print('Ocurrió un error de conexión: $e');
      return [];
    }
  }
}
