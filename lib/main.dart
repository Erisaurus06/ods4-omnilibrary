import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/theme_provider.dart';
import 'services/local_db_service.dart';

void main() async {
  // Aseguramos que los motores nativos estén listos antes de inicializar la BD
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDbService.init();

  runApp(
    // Envolvemos toda la aplicación en el Provider para el cambio de temas
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const OmniLibraryApp(),
    ),
  );
}

class OmniLibraryApp extends StatelessWidget {
  const OmniLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos los cambios del Modo Oscuro
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'OmniLibrary',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(
          0xFFFAFAFA,
        ), // Tu fondo blanco roto
        primaryColor: Colors.black,
        cardColor: Colors.white,
        dividerColor: Colors.grey[300],
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(
          0xFF121212,
        ), // Tu fondo oscuro elegante
        primaryColor: Colors.white,
        cardColor: const Color(0xFF1E1E1E),
        dividerColor: Colors.grey[800],
        // Esto asegura que la base se ponga oscura automáticamente
        colorScheme: const ColorScheme.dark(surface: Color(0xFF1E1E1E)),
      ),
      home: const HomeScreen(),
    );
  }
}
