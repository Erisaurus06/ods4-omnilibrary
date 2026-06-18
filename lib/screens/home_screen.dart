import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:light/light.dart';
import 'package:local_auth/local_auth.dart';

// Importamos los nuevos Tabs modulares
import '../providers/theme_provider.dart';
import 'tabs/apuntes_tab.dart';
import 'tabs/flashcards_tab.dart';
import 'tabs/biblioteca_tab.dart';
import 'tabs/ajustes_tab.dart';
import 'tabs/tareas_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indiceActual = 0;
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticated = false;
  Light? _light;
  StreamSubscription? _lightSubscription;

  @override
  void initState() {
    super.initState();
    _authenticate();
    _initLightSensor();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '¡Bienvenido a OmniLibrary! 👋',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(context).primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    });
  }

  Future<void> _authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (canAuthenticate) {
        final bool didAuthenticate = await _auth.authenticate(
          localizedReason: 'Desbloquea tu biblioteca con tu biometría',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );
        setState(() => _isAuthenticated = didAuthenticate);
      } else {
        setState(() => _isAuthenticated = true);
      }
    } catch (e) {
      setState(() => _isAuthenticated = true);
    }
  }

  void _initLightSensor() {
    _light = Light();
    try {
      _lightSubscription = _light?.lightSensorStream.listen((int luxValue) {
        final themeProvider = Provider.of<ThemeProvider>(
          context,
          listen: false,
        );

        if (luxValue < 15 && !themeProvider.isDarkMode) {
          themeProvider.toggleTheme(true);
        } else if (luxValue > 400 && themeProvider.isDarkMode) {
          themeProvider.toggleTheme(false);
        }

        double targetBrightness = (luxValue / 1000).clamp(0.1, 1.0);
        ScreenBrightness().setScreenBrightness(targetBrightness);
      });
    } catch (e) {
      debugPrint("No se pudo iniciar el sensor de luz: $e");
    }
  }

  @override
  void dispose() {
    _lightSubscription?.cancel();
    ScreenBrightness().resetScreenBrightness();
    super.dispose();
  }

  final List<Widget> _pantallas = const [
    ApuntesTab(),
    SeccionTareas(),
    FlashcardsTab(),
    BibliotecaTab(),
    AjustesTab(),
  ];
  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        body: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.lock,
                      size: 80, color: CupertinoColors.systemGrey),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Biblioteca Bloqueada',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).primaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _authenticate();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: const Text(
                        'Desbloquear',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _indiceActual, children: _pantallas),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.65),
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: BottomNavigationBar(
                  currentIndex: _indiceActual,
                  elevation: 0,
                  onTap: (indice) {
                    HapticFeedback.lightImpact();
                    setState(() => _indiceActual = indice);
                  },
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.transparent,
                  selectedItemColor: Theme.of(context).primaryColor,
                  unselectedItemColor: CupertinoColors.systemGrey,
                  showSelectedLabels: true,
                  showUnselectedLabels: true,
                  selectedLabelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  items: const [
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(CupertinoIcons.doc_text),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(CupertinoIcons.doc_text_fill),
                      ),
                      label: 'Apuntes',
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(CupertinoIcons.check_mark_circled),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(CupertinoIcons.check_mark_circled_solid),
                      ),
                      label: 'Tareas',
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(CupertinoIcons.rectangle_stack_person_crop),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(
                            CupertinoIcons.rectangle_stack_person_crop_fill),
                      ),
                      label: 'Flashcards',
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(CupertinoIcons.book),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(CupertinoIcons.book_solid),
                      ),
                      label: 'Biblioteca',
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(CupertinoIcons.settings),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(CupertinoIcons.settings_solid),
                      ),
                      label: 'Ajustes',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
