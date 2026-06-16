import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/library_provider.dart';
import 'services/local_db_service.dart';
import 'services/supabase_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_native_splash/flutter_native_splash.dart'; // Comentado temporalmente

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Retenemos el Splash Screen nativo en pantalla (Desactivado temporalmente)
  // FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 2. Cargamos configuración primero
  await dotenv.load(fileName: ".env");

  await LocalDbService.init();
  await SupabaseService.inicializar();

  // 4. Verificamos si es la primera vez que se abre la app
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  // 5. Todo listo. Quitamos el Splash Screen suavemente (Desactivado temporalmente)
  // FlutterNativeSplash.remove();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
      ],
      child: OmniLibraryApp(hasSeenOnboarding: hasSeenOnboarding),
    ),
  );
}

class OmniLibraryApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  const OmniLibraryApp({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {

    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'OmniLibrary',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      themeAnimationDuration: const Duration(
        milliseconds: 600,
      ), 
      themeAnimationCurve: Curves.easeInOutCubic, 
      theme: ThemeData(
        fontFamily: '.SF Pro Text',
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
          0xFF000000, 
        ),
        primaryColor: Colors.white,
        cardColor: const Color(
          0xFF1C1C1E,
        ), 
        dividerColor: Colors.grey[800],
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
      home: AuthGate(hasSeenOnboarding: hasSeenOnboarding),
    );
  }
}

/// Wrapper que verifica el estado de la sesión de Supabase en tiempo real
class AuthGate extends StatelessWidget {
  final bool hasSeenOnboarding;
  const AuthGate({super.key, required this.hasSeenOnboarding});

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
        return hasSeenOnboarding
            ? const AuthScreen()
            : const OnboardingScreen();
      },
    );
  }
}
