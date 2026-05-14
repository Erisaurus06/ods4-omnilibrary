import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // Marcará error temporalmente, es normal

void main() {
  runApp(const OmniLibraryApp());
}

class OmniLibraryApp extends StatelessWidget {
  const OmniLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OmniLibrary',
      debugShowCheckedModeBanner:
          false, // Quitamos la molesta etiqueta de "DEBUG"
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor:
              Colors.blueGrey, // Un color base sobrio, ideal para lectura
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      // La app se adapta automáticamente al tema claro/oscuro del celular del usuario
      themeMode: ThemeMode.system,
      home: const HomeScreen(), // Aquí llamamos a tu pantalla principal
    );
  }
}
