import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/library_provider.dart';
import 'providers/news_provider.dart';
import 'providers/explore_provider.dart';
import 'services/local_db_service.dart';
import 'services/supabase_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Cargamos configuración primero
  await dotenv.load(fileName: ".env");

  // 2. Inicializamos servicios (Base de datos local + Nube)
  await LocalDbService.init();
  await SupabaseService.inicializar(); // Esta línea se encarga de todo lo de Supabase

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
        ChangeNotifierProvider(create: (_) => ExploreProvider()),
      ],
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
        fontFamily: '.SF Pro Text', // Fuerza San Francisco en iOS/macOS
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(
          0xFFFAFAFA,
        ), // Tu fondo blanco roto
        primaryColor: Colors.black,
        cardColor: Colors.white,
        dividerColor: Colors.grey[300],
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
      ),
      darkTheme: ThemeData(
        fontFamily: '.SF Pro Text',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(
          0xFF000000, // Negro puro típico de iOS para pantallas OLED
        ),
        primaryColor: Colors.white,
        cardColor: const Color(
          0xFF1C1C1E,
        ), // Color de las tarjetas en iOS Dark Mode
        dividerColor: Colors.grey[800],
        // Esto asegura que la base se ponga oscura automáticamente
        colorScheme: const ColorScheme.dark(surface: Color(0xFF1C1C1E)),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// Wrapper que verifica el estado de la sesión de Supabase en tiempo real
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SupabaseService.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final session = snapshot.data?.session;
        if (session != null) {
          return const HomeScreen(); // Usuario logueado
        }
        return const AuthScreen(); // Pedir inicio de sesión
      },
    );
  }
}
