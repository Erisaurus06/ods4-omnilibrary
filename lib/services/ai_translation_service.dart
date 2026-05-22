class AiTranslationService {
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
}
