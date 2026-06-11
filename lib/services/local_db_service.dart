import 'package:hive_flutter/hive_flutter.dart';

class LocalDbService {
  static const String _boxName = 'bibliotecaBox';
  static const String _citasBox = 'citasBox';
  static const String _progresoBox = 'progresoBox';
  static const String _noticiasBox = 'noticiasBox';
  static const String _notasBox = 'notasBox';
  static const String _flashcardsBox = 'flashcardsBox';
  static const String _tareasBox = 'tareasBox';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
    await Hive.openBox<List<dynamic>>(_citasBox);
    await Hive.openBox<dynamic>(_progresoBox);
    await Hive.openBox<String>(_noticiasBox);
    await Hive.openBox<List<dynamic>>(_notasBox);
    await Hive.openBox<List<dynamic>>(_flashcardsBox);
    await Hive.openBox<List<dynamic>>(_tareasBox);
  }

  static Box<Map<dynamic, dynamic>> get _box =>
      Hive.box<Map<dynamic, dynamic>>(_boxName);

  static List<Map<String, dynamic>> obtenerDocumentos() {
    // Convertimos los datos guardados a nuestro formato de Mapa original
    return _box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> guardarDocumento(Map<String, dynamic> doc) async {
    await _box.add(doc);
  }

  static Future<void> actualizarDocumento(
    int index,
    Map<String, dynamic> doc,
  ) async {
    await _box.putAt(index, doc);
  }

  // Método para eliminar documentos de la biblioteca
  static Future<void> eliminarDocumento(int index) async {
    await _box.deleteAt(index);
  }

  // --- Notas (Post-its) ---
  static Box<List<dynamic>> get _boxNotas => Hive.box<List<dynamic>>(_notasBox);

  static List<Map<String, String>> obtenerNotas() {
    // Obtenemos la lista dinámica y la transformamos de vuelta a Map<String, String>
    final lista = _boxNotas.get('notas_lista', defaultValue: []) ?? [];
    return lista.map((e) {
      final map = e as Map;
      return map.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }).toList();
  }

  static Future<void> guardarNotas(List<Map<String, String>> notas) async {
    await _boxNotas.put('notas_lista', notas);
  }

  // --- Flashcards ---
  static Box<List<dynamic>> get _boxFlashcards =>
      Hive.box<List<dynamic>>(_flashcardsBox);

  static List<Map<String, String>> obtenerFlashcards() {
    final lista =
        _boxFlashcards.get('flashcards_lista', defaultValue: []) ?? [];
    return lista.map((e) {
      final map = e as Map;
      return map.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }).toList();
  }

  static Future<void> guardarFlashcards(
    List<Map<String, String>> flashcards,
  ) async {
    await _boxFlashcards.put('flashcards_lista', flashcards);
  }

  // --- Tareas ---
  static Box<List<dynamic>> get _boxTareas =>
      Hive.box<List<dynamic>>(_tareasBox);

  static List<Map<String, dynamic>> obtenerTareas() {
    final lista = _boxTareas.get('tareas_lista', defaultValue: []) ?? [];
    return lista.map((e) {
      final map = e as Map;
      return map.map((key, value) => MapEntry(key.toString(), value));
    }).toList();
  }

  static Future<void> guardarTareas(List<Map<String, dynamic>> tareas) async {
    await _boxTareas.put('tareas_lista', tareas);
  }

  // --- Citas ---
  static Box<List<dynamic>> get _boxCitas => Hive.box<List<dynamic>>(_citasBox);

  static List<String> obtenerCitas() {
    return _boxCitas.get('citas_lista', defaultValue: [])?.cast<String>() ?? [];
  }

  static Future<void> guardarCita(String cita) async {
    final citas = obtenerCitas();
    citas.insert(0, cita);
    await _boxCitas.put('citas_lista', citas);
  }

  static Future<void> eliminarCita(int index) async {
    final citas = obtenerCitas();
    if (index >= 0 && index < citas.length) {
      citas.removeAt(index);
      await _boxCitas.put('citas_lista', citas);
    }
  }

  // --- Progreso ---
  static Box<dynamic> get _boxProgreso => Hive.box<dynamic>(_progresoBox);

  static dynamic obtenerProgreso(String key) {
    return _boxProgreso.get(key);
  }

  static Future<void> guardarProgreso(String key, dynamic progreso) async {
    await _boxProgreso.put(key, progreso);
  }

  // --- Noticias Caché ---
  static Box<String> get _boxNoticias => Hive.box<String>(_noticiasBox);

  static String? obtenerNoticias(String categoria) {
    return _boxNoticias.get(categoria);
  }

  static Future<void> guardarNoticias(String categoria, String xml) async {
    await _boxNoticias.put(categoria, xml);
  }

  // --- Funciones Reales de Almacenamiento ---
  static Future<void> limpiarCache() async {
    await _boxNoticias.clear();
  }

  static String obtenerTamanoCache() {
    int bytes = 0;
    // Simulamos el peso en bytes sumando la longitud de los strings guardados
    for (var xml in _boxNoticias.values) {
      bytes += xml.toString().length;
    }

    if (bytes == 0) return '0 KB';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
