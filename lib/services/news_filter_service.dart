class NewsFilterService {
  // Pesos asignados a cada categoría o palabra clave (De 0.0 a 1.0)
  final Map<String, double> _keywordWeights = {
    'historia': 0.9,
    'filosofía': 1.0,
    'filosofia': 1.0,
    'tecnología': 0.8,
    'tecnologia': 0.8,
    'ciencia': 0.7,
    'desarrollo': 0.6,
    'sociedad': 0.5,
  };

  /// Evalúa el texto y retorna un puntaje acumulativo de relevancia.
  double evaluateRelevance(String text) {
    if (text.trim().isEmpty) return 0.0;

    double totalScore = 0.0;
    final lowerCaseText = text.toLowerCase();

    _keywordWeights.forEach((keyword, weight) {
      if (lowerCaseText.contains(keyword)) {
        totalScore += weight;
      }
    });

    // Retorna el puntaje, limitando opcionalmente el máximo a 1.0 si lo requieres.
    // En este caso, lo dejaremos como una suma neta.
    return totalScore;
  }

  /// Determina si un texto pasa el umbral mínimo para mostrarse al usuario.
  bool isRelevant(String text, {double threshold = 0.8}) {
    final score = evaluateRelevance(text);
    return score >= threshold;
  }
}
