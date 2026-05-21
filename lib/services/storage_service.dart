import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  final Dio _dio = Dio();

  /// Obtiene la ruta del directorio interno donde se guardarán los archivos
  Future<String> _getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Verifica si un documento ya existe localmente
  Future<bool> fileExists(String filename) async {
    final path = await _getLocalPath();
    final file = File('$path/$filename');
    return file.exists();
  }

  /// Descarga un archivo silenciosamente, ignorando si ya está descargado.
  Future<String?> downloadFileSilently(String url, String filename) async {
    try {
      final path = await _getLocalPath();
      final filePath = '$path/$filename';

      if (await fileExists(filename)) {
        // Retornamos la ruta si ya existe para ahorrar datos móviles
        return filePath;
      }

      await _dio.download(url, filePath);
      return filePath;
    } catch (e) {
      print('Error en la descarga silenciosa: $e');
      return null;
    }
  }
}
