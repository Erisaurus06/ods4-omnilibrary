import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/library_provider.dart';
import 'services/local_db_service.dart';
import 'services/supabase_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/light_sensor_service.dart';
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

  // Iniciamos el sensor de luz ambiental para el cambio automático de tema
  LightSensorService().startListening();

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

class OmniLibraryApp extends StatefulWidget {
  final bool hasSeenOnboarding;
  const OmniLibraryApp({super.key, required this.hasSeenOnboarding});

  @override
  State<OmniLibraryApp> createState() => _OmniLibraryAppState();
}

class _OmniLibraryAppState extends State<OmniLibraryApp> {
  @override
  void initState() {
    super.initState();
    // Escuchamos los cambios del sensor de luz en tiempo real
    LightSensorService().isDarkModeStream.listen((isDark) {
      if (mounted) {
        Provider.of<ThemeProvider>(context, listen: false).toggleTheme(isDark);
      }
    });
  }

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
          0xFFF2F2F7, // Fondo agrupado nativo de iOS (Light)
        ),
        primaryColor: Colors.black,
        cardColor: Colors.white,
        dividerColor: Colors.grey[300],
        splashColor: Colors.transparent, // Regla 5: Sin ripples de Material
        highlightColor: Colors.transparent,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
        cupertinoOverrideTheme: const NoDefaultCupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: CupertinoColors.activeBlue,
          scaffoldBackgroundColor: Color(0xFFF2F2F7),
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
        splashColor: Colors.transparent, // Regla 5: Sin ripples de Material
        highlightColor: Colors.transparent,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        colorScheme: const ColorScheme.dark(surface: Color(0xFF1C1C1E)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
        cupertinoOverrideTheme: const NoDefaultCupertinoThemeData(
          brightness: Brightness.dark,
          primaryColor: CupertinoColors.activeBlue,
          scaffoldBackgroundColor: Color(0xFF000000),
        ),
      ),
      home: AuthGate(hasSeenOnboarding: widget.hasSeenOnboarding),
    );
  }
}

/// Wrapper que verifica el estado de la sesión de Supabase en tiempo real
class AuthGate extends StatefulWidget {
  final bool hasSeenOnboarding;
  const AuthGate({super.key, required this.hasSeenOnboarding});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Escuchar eventos de autenticación para mostrar SnackBars elegantes nativos
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        HapticFeedback.mediumImpact(); // Regla 5: Haptics
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              behavior: SnackBarBehavior.floating,
              padding: const EdgeInsets.all(16),
              content: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.04), // Regla 3: Sombras suaves
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16), // Regla 3: Squarcles
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                        sigmaX: 25, sigmaY: 25), // Regla 1: Glassmorphism
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      color: Colors.green.withOpacity(0.75),
                      child: const Text('✅ Inicio de sesión exitoso',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      } else if (event == AuthChangeEvent.signedOut) {
        HapticFeedback.lightImpact(); // Regla 5: Haptics
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              behavior: SnackBarBehavior.floating,
              padding: const EdgeInsets.all(16),
              content: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      color: Colors.black.withOpacity(0.75),
                      child: const Text('👋 Sesión cerrada',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
    });
  }

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
        return widget.hasSeenOnboarding
            ? const AuthScreen()
            : const OnboardingScreen();
      },
    );
  }
}
