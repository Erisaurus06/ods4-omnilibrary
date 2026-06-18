import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiTranslationService {
  // Extraemos la llave de forma segura usando flutter_dotenv (oculta en el archivo .env)
  static String get _geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  /// Genera un prompt contextualizado basado en el tipo de lectura,
  /// asegurando que el modelo de Inteligencia Artificial entienda las
  /// reglas de retención de formato nativo, OCR y saltos de línea.
  String generateTranslationPrompt({
    required String documentType,
    required String originalText,
    String targetLanguage = 'español',
  }) {
    String basePrompt = 'Actúa como un traductor literario y técnico experto. ';

    switch (documentType.toLowerCase()) {
      case 'idiomas':
      case 'languagebook':
        basePrompt +=
            'El siguiente texto pertenece a un libro de aprendizaje de idiomas. Tu objetivo es TRADUCIR ÚNICAMENTE al $targetLanguage '
            'las explicaciones teóricas y narrativas. Debes MANTENER en su idioma original absolutamente todos los ejemplos, '
            'diálogos de práctica, vocabularios en bruto y ejercicios. Es crucial que no traduzcas las partes que el estudiante debe practicar.\n\n';
        break;
      case 'manga':
      case 'comic':
        basePrompt +=
            'El siguiente texto fue extraído mediante un sistema OCR de un manga. Traduce el contenido al $targetLanguage '
            'manteniendo intactos el tono, el nivel de agresividad/formalidad y adaptando onomatopeyas. '
            'Es una REGLA ABSOLUTA PRESERVAR EXACTAMENTE los saltos de línea originales (\\n) para que el texto encaje de forma '
            'milimétrica de regreso en las burbujas de diálogo sin dañar el arte visual. No agregues comillas ni explicaciones extra.\n\n';
        break;
      default:
        basePrompt +=
            'Traduce el siguiente documento de forma íntegra y elegante al $targetLanguage, respetando rigurosamente la estructura, '
            'las sangrías, los párrafos y el tono original del autor. Retorna únicamente el texto traducido sin notas ni metadata.\n\n';
    }

    // Retornamos el payload inyectado con los metadatos requeridos por la IA
    return '$basePrompt--- TEXTO ORIGINAL ---\n$originalText\n--- FIN TEXTO ORIGINAL ---';
  }

  /// Genera un prompt para resumir un documento PDF extraído
  String generateSummaryPrompt({
    required String documentTitle,
    required String originalText,
  }) {
    return 'Actúa como un asistente de estudio experto. Resume el siguiente texto extraído del documento "$documentTitle" en un párrafo conciso y fácil de entender, destacando los puntos principales.\n\n--- TEXTO ---\n$originalText\n--- FIN TEXTO ---';
  }

  /// Genera un prompt para que la IA cree flashcards a partir de un texto.
  String generateFlashcardsPrompt({required String text}) {
    return '''
Actúa como un asistente de estudio experto. Tu tarea es analizar el siguiente texto y generar un conjunto de flashcards (pregunta y respuesta) para ayudar a un estudiante a memorizar los conceptos clave.

REGLAS ESTRICTAS:
1.  Extrae únicamente los conceptos más importantes y fundamentales. No crees flashcards sobre datos triviales.
2.  Las preguntas deben ser claras y directas.
3.  Las respuestas deben ser concisas y fáciles de entender.
4.  Genera un MÁXIMO de 10 flashcards.
5.  Debes devolver la respuesta EXCLUSIVAMENTE en formato JSON, como un array de objetos. No incluyas texto introductorio, explicaciones ni la palabra "json".
6.  Cada objeto en el array debe tener tres claves: "titulo" (para la pregunta/concepto), "contenido" (para la respuesta/definición) y "color".
7.  Asigna un color pastel aleatorio a cada flashcard. Elige entre estos colores: '0xFFFFF59D' (amarillo), '0xFFB39DDB' (morado), '0xFFA5D6A7' (verde), '0xFF90CAF9' (azul), '0xFFFFAB91' (naranja).

EJEMPLO DE SALIDA JSON:
[
  {
    "titulo": "¿Qué es la fotosíntesis?",
    "contenido": "Es el proceso en el cual la energía de la luz se convierte en energía química en forma de azúcares, usando agua y dióxido de carbono.",
    "color": "0xFFFFF59D"
  },
  {
    "titulo": "Productos de la fotosíntesis",
    "contenido": "Glucosa (azúcares) que proporciona energía y carbono, y oxígeno como subproducto.",
    "color": "0xFFA5D6A7"
  }
]

--- TEXTO A ANALIZAR ---
$text
--- FIN DEL TEXTO ---
''';
  }

  /// Llama a la API de Gemini para generar flashcards a partir de un texto.
  Future<List<Map<String, String>>> getFlashcardsFromText(String text) async {
    final prompt = generateFlashcardsPrompt(text: text);
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey',
    );

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {"text": prompt},
                  ],
                },
              ],
              "generationConfig": {"responseMimeType": "application/json"},
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['candidates'] == null ||
            (data['candidates'] as List).isEmpty) {
          return [];
        }

        String jsonText = data['candidates'][0]['content']['parts'][0]['text'];
        // Limpiar posible formato markdown residual (Gemini suele agregarlo incluso con application/json)
        jsonText = jsonText
            .replaceAll(RegExp(r'```json\n?'), '')
            .replaceAll(RegExp(r'```\n?'), '')
            .trim();

        final List<dynamic> flashcardList = jsonDecode(jsonText);
        return flashcardList.map((item) {
          final map = item as Map<String, dynamic>;
          return {
            'titulo': map['titulo']?.toString() ?? 'Sin título',
            'contenido': map['contenido']?.toString() ?? 'Sin contenido',
            'color': map['color']?.toString() ?? '0xFFFFF59D',
          };
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Método simulado de conexión con IA para obtener el resumen.
  /// Aquí debes conectar tu endpoint real (OpenAI, Gemini, Claude, etc).
  Future<String> getResumen(String title, String text) async {
    final prompt = generateSummaryPrompt(
      documentTitle: title,
      originalText: text,
    );
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey',
    );

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {"text": prompt},
                  ],
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['candidates'] == null ||
            (data['candidates'] as List).isEmpty) {
          return 'El contenido fue bloqueado o no se pudo generar el resumen.';
        }

        final generatedText =
            data['candidates'][0]['content']['parts'][0]['text'];
        return '✨ Resumen de la IA:\n\n$generatedText';
      } else {
        return 'Error al consultar la IA. Código: ${response.statusCode}\nDetalles: ${response.body}';
      }
    } catch (e) {
      return 'No se pudo conectar con el servicio de IA. Verifica tu conexión a internet o tu API Key.\nError: $e';
    }
  }
}
