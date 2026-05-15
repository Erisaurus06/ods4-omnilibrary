import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() async {
  // --- PREPARACIÓN PARA FIREBASE ---
  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();

  runApp(const OmniLibraryApp());
}

class OmniLibraryApp extends StatelessWidget {
  const OmniLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OmniLibrary',
      debugShowCheckedModeBanner: false,
      // DISEÑO MINIMALISTA: Blancos, negros y grises
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(
          0xFFFAFAFA,
        ), // Un blanco roto muy elegante
        colorScheme: const ColorScheme.light(
          primary: Colors.black, // Botones principales en negro
          secondary: Colors.grey,
          surface: Colors.white, // Tarjetas blancas
          background: Color(0xFFFAFAFA),
        ),
        useMaterial3: true,
        // Al no definir 'fontFamily', usará la nativa de iOS y Android automáticamente
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFAFAFA),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing:
                -0.5, // Letras ligeramente más juntas (toque premium)
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
