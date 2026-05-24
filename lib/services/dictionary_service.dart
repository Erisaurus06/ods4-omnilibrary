import 'dart:convert';
import 'package:http/http.dart' as http;

class DictionaryService {
  /// Consulta la API gratuita de diccionarios para obtener la definición en español.
  static Future<String> definirPalabra(String palabra) async {
    final String palabraLimpia = Uri.encodeComponent(
      palabra.toLowerCase().trim(),
    );
    final url = Uri.parse(
      'https://api.dictionaryapi.dev/api/v2/entries/es/$palabraLimpia',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Retorna la primera definición encontrada
        return data[0]['meanings'][0]['definitions'][0]['definition'];
      }
      return 'No se encontró una definición exacta para "$palabra".';
    } catch (e) {
      return 'Error de conexión al buscar la palabra.';
    }
  }
}
