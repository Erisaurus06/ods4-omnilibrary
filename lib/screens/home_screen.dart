import 'package:flutter/material.dart';
import 'package:omnilibrary/screens/reader_screen.dart';
import 'package:omnilibrary/services/wikipedia_service.dart';
import 'package:omnilibrary/services/rss_service.dart';
import 'package:dart_rss/dart_rss.dart';
import 'package:file_picker/file_picker.dart';
import 'package:omnilibrary/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:omnilibrary/services/news_filter_service.dart';
import '../providers/theme_provider.dart';
import '../providers/library_provider.dart';
import '../providers/news_provider.dart';
import '../providers/explore_provider.dart';
import '../services/local_db_service.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../services/ai_translation_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/supabase_service.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/google_search_service.dart';
import '../services/google_books_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indiceActual = 0; // Controla en qué pestaña estamos

  final List<Widget> _pantallas = [
    const _SeccionExplorar(),
    const _SeccionNoticias(),
    const _SeccionBiblioteca(),
    const _SeccionAjustes(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody:
          true, // Esto permite que el contenido pase por debajo del menú para revelar el desenfoque
      body: IndexedStack(index: _indiceActual, children: _pantallas),
      // --- BARRA DE NAVEGACIÓN PREMIUM ---
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 25, // Desenfoque más profundo estilo iOS
            sigmaY: 25,
          ), // El nivel de desenfoque
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).cardColor.withOpacity(0.65), // Color semi-transparente
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 0.5,
                ), // Reflejo del cristal superior
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
                    HapticFeedback.lightImpact(); // Vibración sutil premium
                    setState(() => _indiceActual = indice);
                  },
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.transparent,
                  selectedItemColor: Theme.of(context).primaryColor,
                  unselectedItemColor: Colors.grey[400],
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
                        child: Icon(Icons.explore_outlined),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.explore),
                      ),
                      label: 'Explorar',
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.newspaper_outlined),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.newspaper),
                      ),
                      label: 'Noticias',
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.book_outlined),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.book),
                      ),
                      label: 'Biblioteca',
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.settings_outlined),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.settings),
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

// --- SECCIÓN 4: AJUSTES (Configuración y APIs) ---

void _mostrarVincularGoogleBooks(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.library_books, size: 60, color: Colors.blue[400]),
            const SizedBox(height: 16),
            Text(
              'Vincular Google Play Books',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Al vincular tu cuenta, OmniLibrary podrá acceder a tus libros comprados y ePubs sincronizados usando la API oficial de Google Books OAuth 2.0.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).primaryColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.login),
                label: const Text('Autenticar con Google'),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Simulando conexión segura OAuth...'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SeccionAjustes extends StatefulWidget {
  const _SeccionAjustes();

  @override
  State<_SeccionAjustes> createState() => _SeccionAjustesState();
}

class _SeccionAjustesState extends State<_SeccionAjustes> {
  bool _modoLectura = true;

  @override
  Widget build(BuildContext context) {
    // Accedemos al estado global del Tema
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(
            fontSize: 34, // Large Title de iOS
            fontWeight: FontWeight.bold,
            letterSpacing: -1.2,
          ),
        ),
        centerTitle: false,
        toolbarHeight: 80,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        children: [
          // --- 1. CUENTA ---
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'CUENTA',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _ActionTile(
                  titulo: 'Cerrar Sesión',
                  icono: Icons.person,
                  colorIcono: Colors.redAccent,
                  trailingText:
                      SupabaseService.client.auth.currentUser?.email ??
                      'Usuario',
                  onTap: () async {
                    await SupabaseService.client.auth.signOut();
                  },
                ),
                Divider(
                  height: 1,
                  indent: 50,
                  color: Theme.of(context).dividerColor?.withOpacity(0.5),
                ),
                _ActionTile(
                  titulo: 'Sincronización en la Nube',
                  icono: Icons.cloud_sync,
                  colorIcono: Colors.indigo,
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          // --- 2. APARIENCIA ---
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'APARIENCIA',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(
                10,
              ), // Radio Inset Grouped nativo
            ),
            child: Column(
              children: [
                _SwitchTile(
                  titulo: 'Modo Oscuro',
                  subtitulo: 'Cambia el tema de la aplicación',
                  icono: Icons.dark_mode_outlined,
                  valor: themeProvider.isDarkMode,
                  onChanged: (val) => themeProvider.toggleTheme(val),
                ),
                Divider(
                  height: 1,
                  indent: 64,
                  color: Theme.of(context).dividerColor?.withOpacity(0.5),
                ),
                _SwitchTile(
                  titulo: 'Modo Lectura',
                  subtitulo: 'Optimiza el contraste y la tipografía',
                  icono: Icons.menu_book_outlined,
                  valor: _modoLectura,
                  onChanged: (val) => setState(() => _modoLectura = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          // --- 3. INTEGRACIONES Y APIS ---
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'INTEGRACIONES Y APIS',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                const _ApiTile(
                  titulo: 'Wikipedia API',
                  subtitulo: 'Búsquedas globales',
                  icono: Icons.language,
                  conectado: true,
                ),
                Divider(
                  height: 1,
                  indent: 64,
                  color: Theme.of(context).dividerColor?.withOpacity(0.5),
                ),
                const _ApiTile(
                  titulo: 'Noticias RSS',
                  subtitulo: 'Actualidad',
                  icono: Icons.rss_feed,
                  conectado: true,
                ),
                Divider(
                  height: 1,
                  indent: 64,
                  color: Theme.of(context).dividerColor?.withOpacity(0.5),
                ),
                _ApiTile(
                  titulo: 'Google Play Books',
                  subtitulo: 'Autenticación',
                  icono: Icons.library_books_outlined,
                  conectado: false,
                  onTap: () => _mostrarVincularGoogleBooks(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          // --- 4. ALMACENAMIENTO Y DATOS ---
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'ALMACENAMIENTO Y DATOS',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _ActionTile(
                  titulo: 'Gestionar Almacenamiento',
                  icono: Icons.storage,
                  colorIcono: Colors.green,
                  trailingText: '1.2 GB',
                  onTap: () {},
                ),
                Divider(
                  height: 1,
                  indent: 50,
                  color: Theme.of(context).dividerColor?.withOpacity(0.5),
                ),
                _ActionTile(
                  titulo: 'Borrar Caché Local',
                  icono: Icons.delete_sweep,
                  colorIcono: Colors.red,
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          // --- 5. ACERCA DE ---
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'ACERCA DE',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _ActionTile(
                  titulo: 'Versión de la App',
                  icono: Icons.info_outline,
                  colorIcono: Colors.orange,
                  trailingText: '1.0.0',
                  onTap: () {},
                ),
                Divider(
                  height: 1,
                  indent: 50,
                  color: Theme.of(context).dividerColor?.withOpacity(0.5),
                ),
                _ActionTile(
                  titulo: 'Términos y Privacidad',
                  icono: Icons.shield_outlined,
                  colorIcono: Colors.blueGrey,
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final bool valor;
  final Function(bool) onChanged;

  const _SwitchTile({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      activeColor: Theme.of(context).primaryColor,
      title: Text(
        titulo,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      subtitle: Text(
        subtitulo,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).primaryColor.withOpacity(0.6),
        ),
      ),
      secondary: Container(
        // Cuadro redondeado estilo Apple Settings
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icono,
          color: Theme.of(context).scaffoldBackgroundColor,
          size: 20,
        ),
      ),
      value: valor,
      onChanged: onChanged,
    );
  }
}

class _ApiTile extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final bool conectado;
  final VoidCallback? onTap; // NUEVO: Permite hacer clic en la API

  const _ApiTile({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.conectado,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: conectado ? primaryColor : Colors.grey[400],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icono,
          color: Theme.of(context).scaffoldBackgroundColor,
          size: 20,
        ),
      ),
      title: Text(
        titulo,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      subtitle: Text(
        subtitulo,
        style: TextStyle(fontSize: 13, color: primaryColor.withOpacity(0.6)),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.withOpacity(0.5)),
      onTap: onTap,
    );
  }
}

// --- NUEVO TILE ESTILO iOS PARA ACCIONES GLOBALES ---
class _ActionTile extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color colorIcono;
  final String? trailingText;
  final VoidCallback onTap;

  const _ActionTile({
    required this.titulo,
    required this.icono,
    required this.colorIcono,
    this.trailingText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: colorIcono,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icono, color: Colors.white, size: 20),
      ),
      title: Text(
        titulo,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText!,
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),
          if (trailingText != null) const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: Colors.grey.withOpacity(0.5)),
        ],
      ),
      onTap: onTap,
    );
  }
}

// --- SECCIÓN 1: EXPLORAR (Lo que ya teníamos programado) ---
class _SeccionExplorar extends StatefulWidget {
  const _SeccionExplorar();

  @override
  State<_SeccionExplorar> createState() => _SeccionExplorarState();
}

class _SeccionExplorarState extends State<_SeccionExplorar> {
  bool _isSearching = false;
  List<dynamic> _wikiResultados = [];
  List<dynamic> _pdfResultados = [];
  List<dynamic> _booksResultados = [];

  Future<void> _buscarMultifuente(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);

    try {
      // Ejecutamos las 3 APIs de Google y Wikipedia en paralelo para máxima velocidad
      final results = await Future.wait([
        WikipediaService.buscarArticulos(query),
        GoogleSearchService.buscarDocumentosConfiables(query),
        GoogleBooksService.buscarLibros(query),
      ]);

      setState(() {
        _wikiResultados = results[0];
        _pdfResultados = results[1];
        _booksResultados = results[2];
      });
    } catch (e) {
      print('Error en búsqueda multifuente: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _abrirEnNavegador(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OmniLibrary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.headphones_outlined),
            onPressed: () => print("Deep Link a TecConnection"),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        children: [
          const Text(
            '¿Qué quieres\naprender hoy?',
            style: TextStyle(
              fontSize: 32, // Título largo estilo LargeTitle de iOS
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5, // SF Pro Display negativo
              height: 1.1,
            ),
          ),
          const SizedBox(height: 24),
          _BuscadorUniversal(onBuscar: (query) => _buscarMultifuente(query)),
          const SizedBox(height: 24),
          const _FiltrosCategorias(),
          const SizedBox(height: 36),
          const Text(
            'Resultados de la Búsqueda',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _isSearching
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                )
              : (_wikiResultados.isEmpty &&
                    _pdfResultados.isEmpty &&
                    _booksResultados.isEmpty)
              ? const Text('Sin resultados.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- RESULTADOS GOOGLE BOOKS ---
                    if (_booksResultados.isNotEmpty) ...[
                      const Text(
                        'Libros Encontrados (Google Books)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._booksResultados.take(3).map((libro) {
                        final volumeInfo = libro['volumeInfo'] ?? {};
                        final imageLinks = volumeInfo['imageLinks'] ?? {};
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _TarjetaArticulo(
                            titulo: volumeInfo['title'] ?? 'Sin título',
                            fuente: 'Google Books',
                            tiempoLectura:
                                volumeInfo['authors']?.join(', ') ??
                                'Desconocido',
                            contenido:
                                volumeInfo['description'] ?? 'Sin descripción.',
                            imageUrl: imageLinks['thumbnail']?.replaceFirst(
                              'http:',
                              'https:',
                            ),
                            articleUrl: volumeInfo['infoLink'],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                    ],
                    // --- RESULTADOS PDFs DE LA WEB ---
                    if (_pdfResultados.isNotEmpty) ...[
                      const Text(
                        'Documentos PDF Confiables',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._pdfResultados.take(3).map((pdf) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _TarjetaArticulo(
                            titulo: pdf['title'] ?? 'Documento PDF',
                            fuente: 'Web (Académica)',
                            tiempoLectura: 'PDF',
                            contenido: pdf['snippet'] ?? '',
                            articleUrl: pdf['link'],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                    ],
                    // --- RESULTADOS WIKIPEDIA ---
                    if (_wikiResultados.isNotEmpty) ...[
                      const Text(
                        'Conceptos Base (Wikipedia)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._wikiResultados.take(4).map((wiki) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _TarjetaArticulo(
                            titulo: wiki['title'],
                            fuente: 'Wikipedia',
                            tiempoLectura: 'Concepto',
                            contenido:
                                (wiki['snippet'] ?? '') +
                                '\n\n(Toca para leer completo en la web)',
                            articleUrl:
                                'https://es.wikipedia.org/wiki/${Uri.encodeComponent(wiki['title'])}',
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
        ],
      ),
    );
  }
}

// --- Mantenemos los widgets de _BuscadorUniversal, _FiltrosCategorias y _TarjetaArticulo igual que antes ---
// --- COMPONENTES (WIDGETS) REUTILIZABLES ---

class _BuscadorUniversal extends StatefulWidget {
  final Function(String) onBuscar; // Recibimos la función

  const _BuscadorUniversal({required this.onBuscar});

  @override
  State<_BuscadorUniversal> createState() => _BuscadorUniversalState();
}

class _BuscadorUniversalState extends State<_BuscadorUniversal> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onSubmitted:
          widget.onBuscar, // Activa la búsqueda al dar "Enter" en el teclado
      textInputAction: TextInputAction.search, // Cambia el botón a una lupa
      decoration: InputDecoration(
        hintText: 'Buscar conceptos, noticias...',
        hintStyle: TextStyle(
          color: Theme.of(context).primaryColor.withOpacity(0.5),
        ),
        prefixIcon: Icon(
          Icons.search,
          color: Theme.of(context).primaryColor.withOpacity(0.6),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            Icons.cancel_outlined, // Icono de limpieza minimalista
            color: Theme.of(context).primaryColor.withOpacity(0.4),
          ),
          onPressed: () {
            _controller.clear();
            // Opcional: enfocar el teclado de nuevo aquí si se desea
          },
        ),
        filled: true,
        fillColor: Theme.of(
          context,
        ).primaryColor.withOpacity(0.06), // Fondo de búsqueda iOS (gris tenue)
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10.0, // Altura exacta de iOS
          horizontal: 16.0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), // iOS Search Bar Standard
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            width: 1.0,
          ),
        ),
      ),
    );
  }
}

class _FiltrosCategorias extends StatelessWidget {
  const _FiltrosCategorias();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip('Todo', true, context),
          _buildChip('Wikipedia', false, context),
          _buildChip('Noticias', false, context),
          _buildChip('Podcasts', false, context),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? scaffoldBg : primaryColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        selected: isSelected,
        onSelected: (bool value) {
          HapticFeedback.lightImpact();
        },
        selectedColor: primaryColor,
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide.none,
        ),
      ),
    );
  }
}

// --- NUEVA TARJETA DE ARTÍCULO (Soporta Imágenes y Links) ---
class _TarjetaArticulo extends StatelessWidget {
  final String titulo;
  final String fuente;
  final String tiempoLectura;
  final bool isDestacado;
  final String? contenido;
  final String? imageUrl; // NUEVO: Para la foto de la noticia
  final String? articleUrl; // NUEVO: Para abrir la web original

  const _TarjetaArticulo({
    required this.titulo,
    required this.fuente,
    required this.tiempoLectura,
    this.isDestacado = false,
    this.contenido,
    this.imageUrl,
    this.articleUrl,
  });

  Future<void> _abrirEnNavegador(BuildContext context) async {
    if (articleUrl != null && articleUrl!.isNotEmpty) {
      final uri = Uri.parse(articleUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo abrir el enlace',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Si tiene un link web, abrimos el navegador. Si no, tratamos de abrir el Súper Lector.
        if (articleUrl != null) {
          _abrirEnNavegador(context);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReaderScreen(
                titulo: titulo,
                fuente: fuente,
                contenido: contenido,
              ),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20), // Radio más elevado
          border: Border.all(
            color:
                Theme.of(context).dividerColor?.withOpacity(0.4) ??
                Colors.grey.withOpacity(0.2),
            width: 0.5, // Hairline border
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TEXTO DE LA NOTICIA
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Theme.of(context).primaryColor,
                        height: 1.3,
                        letterSpacing: -0.3, // Texto denso moderno
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (isDestacado)
                          const Padding(
                            padding: EdgeInsets.only(right: 4.0),
                            child: Icon(
                              Icons.local_fire_department,
                              color: Colors.orangeAccent,
                              size: 16,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            '$fuente • $tiempoLectura',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.6),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // IMAGEN DE LA NOTICIA
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        Theme.of(context).dividerColor ??
                        Colors.grey.withOpacity(0.2),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.newspaper,
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.3),
                          ),
                        )
                      : Icon(
                          Icons.article_outlined,
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.5),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- SECCIÓN 2: NOTICIAS (Lector RSS Moderno) ---
class _SeccionNoticias extends StatefulWidget {
  const _SeccionNoticias();

  @override
  State<_SeccionNoticias> createState() => _SeccionNoticiasState();
}

class _SeccionNoticiasState extends State<_SeccionNoticias> {
  final NewsFilterService _newsFilterService = NewsFilterService();

  // Ya no es final para poder agregar nuevas categorías dinámicamente
  List<String> _categorias = [
    'Videojuegos',
    'Nacionales',
    'Internacionales',
    'Seguridad',
  ];

  void _mostrarDialogoNuevaCategoria(
    BuildContext context,
    dynamic newsProvider,
  ) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Añadir Preferencia de Noticias'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Ej. Inteligencia Artificial',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => _categorias.insert(0, controller.text.trim()));
                newsProvider.setCategoria(controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Instanciamos el Provider de Noticias para acceder a `newsProvider`
    final newsProvider = Provider.of<NewsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Actualidad',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.2,
          ),
        ),
        centerTitle: false,
        toolbarHeight: 80,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- CATEGORÍAS HORIZONTALES ---
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _categorias.length + 1,
              itemBuilder: (context, index) {
                if (index == _categorias.length) {
                  return IconButton(
                    icon: Icon(
                      Icons.add_circle,
                      color: Theme.of(context).primaryColor,
                      size: 30,
                    ),
                    onPressed: () =>
                        _mostrarDialogoNuevaCategoria(context, newsProvider),
                  );
                }

                final cat = _categorias[index];
                final isSelected = cat == newsProvider.categoriaSeleccionada;
                final primaryColor = Theme.of(context).primaryColor;
                final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      HapticFeedback.lightImpact();
                      newsProvider.setCategoria(cat);
                    },
                    selectedColor: primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? scaffoldBg : primaryColor,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    backgroundColor: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide.none,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // --- LISTA DE NOTICIAS ---
          Expanded(
            child: Builder(
              builder: (context) {
                if (newsProvider.isLoading && newsProvider.feed == null) {
                  return const _NewsLoadingSkeleton();
                }

                if (newsProvider.feed == null) {
                  return Center(
                    child: Text(
                      'No se pudieron cargar las noticias.',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor.withOpacity(0.6),
                      ),
                    ),
                  );
                }

                final feed = newsProvider.feed!;
                var articulos = feed.items.toList();

                articulos.sort((a, b) {
                  final textoA = '${a.title ?? ''} ${a.description ?? ''}';
                  final textoB = '${b.title ?? ''} ${b.description ?? ''}';

                  final scoreA = newsProvider.newsFilterService
                      .evaluateRelevance(textoA);
                  final scoreB = newsProvider.newsFilterService
                      .evaluateRelevance(textoB);

                  return scoreB.compareTo(
                    scoreA,
                  ); // Orden descendente (Mayor score primero)
                });

                if (articulos.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay noticias para esta categoría.\nIntenta con otra.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor.withOpacity(0.6),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => newsProvider.cargarNoticias(),
                  color: Theme.of(context).primaryColor,
                  backgroundColor: Theme.of(context).cardColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10.0,
                    ),
                    itemCount: articulos.length,
                    itemBuilder: (context, index) {
                      final articulo = articulos[index];
                      final textoEvaluacion =
                          '${articulo.title ?? ''} ${articulo.description ?? ''}';
                      final score = _newsFilterService.evaluateRelevance(
                        textoEvaluacion,
                      );

                      // Limpiar etiquetas HTML de la descripción
                      String cleanDescription = (articulo.description ?? '')
                          .replaceAll(RegExp(r'<[^>]*>'), '');

                      // Extraer imagen si existe en la descripción (Google News lo hace así)
                      String? imageToDisplay;
                      final imgMatch = RegExp(
                        r'src="([^"]+)"',
                      ).firstMatch(articulo.description ?? '');
                      if (imgMatch != null) {
                        imageToDisplay = imgMatch.group(1);
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _TarjetaArticulo(
                          titulo: articulo.title ?? 'Sin título',
                          fuente: feed.title ?? 'Noticias',
                          tiempoLectura: 'Reciente',
                          isDestacado: score > 0.8,
                          contenido: cleanDescription,
                          imageUrl: imageToDisplay,
                          articleUrl: articulo
                              .link, // Pasamos el link directo a la web real
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ), // Cierra Expanded
        ], // Cierra children de Column
      ), // Cierra Column
    ); // Cierra Scaffold
  }
}

// --- SECCIÓN 3: BIBLIOTECA (Tus PDFs y Libros REALES) ---
class _SeccionBiblioteca extends StatefulWidget {
  const _SeccionBiblioteca();

  @override
  State<_SeccionBiblioteca> createState() => _SeccionBibliotecaState();
}

class _SeccionBibliotecaState extends State<_SeccionBiblioteca> {
  final StorageService _storageService = StorageService();
  List<Map<String, dynamic>> _documentos = [];
  bool _vistaCuadricula = false; // Controla si vemos lista o grid

  @override
  void initState() {
    super.initState();
    _cargarBiblioteca();
  }

  // Ahora carga SOLO lo que realmente existe en la base de datos
  void _cargarBiblioteca() {
    final docsDB = LocalDbService.obtenerDocumentos();
    setState(() => _documentos = docsDB);
  }

  // Método para eliminar un documento
  void _borrarDocumento(int index) async {
    await LocalDbService.eliminarDocumento(index);
    _cargarBiblioteca(); // Recargamos la interfaz

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Documento eliminado',
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
          backgroundColor: Theme.of(context).cardColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _agregarArchivoLocal({
    required bool esPdf,
    required bool esEpub,
    required List<String> extensiones,
  }) async {
    Navigator.pop(context); // Cierra el menú inferior
    try {
      FilePickerResult? resultado = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensiones,
      );

      if (resultado != null && resultado.files.single.path != null) {
        final nuevoDoc = {
          'titulo': resultado.files.single.name,
          'descargado': true,
          'esPdf': esPdf,
          'esEpub': esEpub,
          'path': resultado.files.single.path,
          'url': null,
        };

        await LocalDbService.guardarDocumento(nuevoDoc);
        _cargarBiblioteca(); // Actualizamos la lista visual
      }
    } catch (e) {
      print('Error al seleccionar el archivo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Biblioteca',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.2,
          ),
        ),
        toolbarHeight: 80,
        centerTitle: false,
        actions: [
          // Botón para alternar entre Lista y Cuadrícula
          IconButton(
            icon: Icon(
              _vistaCuadricula
                  ? Icons.view_list_rounded
                  : Icons.grid_view_rounded,
            ),
            tooltip: 'Cambiar vista',
            onPressed: () =>
                setState(() => _vistaCuadricula = !_vistaCuadricula),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 90.0,
        ), // ESTO SOLUCIONA LA ORIENTACIÓN Y OVERLAP CON EL MENÚ
        child: FloatingActionButton(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: const Icon(Icons.add),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              backgroundColor: Theme.of(context).cardColor,
              builder: (context) => SafeArea(
                child: Wrap(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Añadir documento',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.picture_as_pdf,
                        color: Theme.of(context).primaryColor,
                      ),
                      title: Text(
                        'Añadir PDF',
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                      onTap: () => _agregarArchivoLocal(
                        esPdf: true,
                        esEpub: false,
                        extensiones: ['pdf'],
                      ),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.book,
                        color: Theme.of(context).primaryColor,
                      ),
                      title: Text(
                        'Añadir Libro (ePub)',
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                      onTap: () => _agregarArchivoLocal(
                        esPdf: false,
                        esEpub: true,
                        extensiones: ['epub'],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      // Si no hay documentos, mostramos una pantalla vacía elegante
      body: _documentos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    size: 80,
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tu biblioteca está vacía',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toca el botón + para añadir PDFs o ePubs.',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            )
          // Si hay documentos, mostramos Cuadrícula o Lista según prefiera el usuario
          : _vistaCuadricula
          ? _construirVistaCuadricula()
          : _construirVistaLista(),
    );
  }

  // --- VISTA 1: LISTA (Con función de deslizar para borrar) ---
  Widget _construirVistaLista() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      itemCount: _documentos.length,
      itemBuilder: (context, index) {
        final doc = _documentos[index];

        return Dismissible(
          key: Key(doc['path'] ?? doc['titulo'] + index.toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red[400],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          onDismissed: (direction) => _borrarDocumento(index),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor ?? Colors.grey,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    doc['esPdf'] == true
                        ? Icons.picture_as_pdf_outlined
                        : Icons.book_outlined,
                    color: Theme.of(context).primaryColor.withOpacity(0.6),
                  ),
                ),
                title: Text(
                  doc['titulo'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Theme.of(context).primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Disponible offline',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
                onTap: () => _abrirLector(doc),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- VISTA 2: CUADRÍCULA (Estilo estantería) ---
  Widget _construirVistaCuadricula() {
    return GridView.builder(
      padding: const EdgeInsets.all(20.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Dos columnas
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75, // Proporción estilo libro
      ),
      itemCount: _documentos.length,
      itemBuilder: (context, index) {
        final doc = _documentos[index];
        return GestureDetector(
          onTap: () => _abrirLector(doc),
          onLongPress: () {
            // Eliminar al mantener presionado en vista grid
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: Theme.of(context).cardColor,
                title: Text(
                  'Eliminar documento',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
                content: Text(
                  '¿Deseas quitar "${doc['titulo']}" de tu biblioteca?',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor.withOpacity(0.8),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _borrarDocumento(index);
                    },
                    child: const Text(
                      'Eliminar',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor ?? Colors.grey,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  doc['esPdf'] == true
                      ? Icons.picture_as_pdf_rounded
                      : Icons.menu_book_rounded,
                  size: 50,
                  color: Theme.of(context).primaryColor.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    doc['titulo'],
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _abrirLector(Map<String, dynamic> doc) {
    if (doc['path'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReaderScreen(
            titulo: doc['titulo'],
            fuente: 'Mi Biblioteca',
            documentPath: doc['path'],
            isPdf: doc['esPdf'] ?? false,
            isEpub: doc['esEpub'] ?? false,
          ),
        ),
      );
    }
  }
}

// --- WIDGET PARA ANIMACIÓN DE CARGA (SKELETON) ---
class _NewsLoadingSkeleton extends StatefulWidget {
  const _NewsLoadingSkeleton();

  @override
  State<_NewsLoadingSkeleton> createState() => _NewsLoadingSkeletonState();
}

class _NewsLoadingSkeletonState extends State<_NewsLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true); // Efecto de latido continuo
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).dividerColor ?? Colors.grey[300]!;

    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_controller),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        itemCount: 5, // Mostramos 5 elementos fantasma
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04), // Súper transparente
                    blurRadius: 24, // Muy difuminado
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16,
                          width: double.infinity,
                          color: dividerColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 16,
                          width: 150,
                          color: dividerColor.withOpacity(0.5),
                        ),
                        const Spacer(),
                        Container(
                          height: 12,
                          width: 100,
                          color: dividerColor.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: dividerColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
