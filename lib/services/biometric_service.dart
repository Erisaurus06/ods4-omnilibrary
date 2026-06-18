import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Solicita autenticación biométrica (Huella/FaceID) al usuario.
  /// Retorna [true] si la autenticación es exitosa o si el dispositivo no la soporta.
  /// Retorna [false] si el usuario cancela o la autenticación falla.
  static Future<bool> authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      // Si el dispositivo no tiene hardware biométrico, lo dejamos continuar.
      if (!canAuthenticate) {
        return true;
      }

      return await _auth.authenticate(
        localizedReason: 'Desbloquea OmniLibrary para acceder a tus documentos',
        options: const AuthenticationOptions(
          biometricOnly: false, // Permite usar PIN o Patrón como respaldo
          stickyAuth:
              true, // Mantiene el diálogo activo si la app pasa a 2do plano
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Error en autenticación biométrica: $e');
      return false;
    }
  }
}
