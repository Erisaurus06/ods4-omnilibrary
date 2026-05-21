import 'package:hive_flutter/hive_flutter.dart';

class LocalDbService {
  static const String _boxName = 'bibliotecaBox';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
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
}
