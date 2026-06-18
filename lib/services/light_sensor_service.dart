import 'dart:async';
import 'package:light/light.dart';
import 'package:flutter/foundation.dart';

class LightSensorService {
  // Patrón Singleton para mantener un único flujo de datos en toda la app
  static final LightSensorService _instance = LightSensorService._internal();
  factory LightSensorService() => _instance;
  LightSensorService._internal();

  Light? _light;
  StreamSubscription? _subscription;

  // Controlador que emitirá 'true' para Modo Oscuro y 'false' para Modo Claro
  final StreamController<bool> _themeModeController =
      StreamController<bool>.broadcast();
  Stream<bool> get isDarkModeStream => _themeModeController.stream;

  bool _isCurrentlyDark = false;

  /// Inicia la lectura del sensor de luz ambiental.
  void startListening() {
    _light = Light();
    try {
      _subscription = _light?.lightSensorStream.listen(_onData);
    } catch (e) {
      debugPrint(
          'El dispositivo no cuenta con sensor de luz ambiental o denegó el permiso: $e');
    }
  }

  void _onData(int luxValue) {
    // Histéresis para evitar parpadeos:
    // Si hay menos de 10 lux (muy oscuro), activamos el Dark Mode.
    if (luxValue < 10 && !_isCurrentlyDark) {
      _isCurrentlyDark = true;
      _themeModeController.add(true);
    }
    // Si hay más de 30 lux (habitación iluminada/sol), activamos el Light Mode.
    else if (luxValue > 30 && _isCurrentlyDark) {
      _isCurrentlyDark = false;
      _themeModeController.add(false);
    }
  }

  /// Detiene el sensor para ahorrar batería cuando la app pasa a segundo plano.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }
}
