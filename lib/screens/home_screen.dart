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
      body: IndexedStack(index: _indiceActual, children: _pantallas),
      // --- BARRA DE NAVEGACIÓN PREMIUM ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
    );
  }
}

// --- SECCIÓN 4: AJUSTES (Configuración y APIs) ---
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
      appBar: AppBar(title: const Text('Configuración'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        children: [
          const Text(
            'Apariencia',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          _SwitchTile(
            titulo: 'Modo Oscuro',
            subtitulo: 'Cambia el tema de la aplicación',
            icono: Icons.dark_mode_outlined,
            valor: themeProvider.isDarkMode,
            onChanged: (val) =>
                themeProvider.toggleTheme(val), // Cambia globalmente
          ),
          const SizedBox(height: 12),
          _SwitchTile(
            titulo: 'Modo Lectura',
            subtitulo: 'Optimiza el contraste y la tipografía',
            icono: Icons.menu_book_outlined,
            valor: _modoLectura,
            onChanged: (val) => setState(() => _modoLectura = val),
          ),
          const SizedBox(height: 36),
          const Text(
            'Integraciones y APIs',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          const _ApiTile(
            titulo: 'Wikipedia API',
            subtitulo: 'Conectado para búsquedas globales',
            icono: Icons.language,
            conectado: true,
          ),
          const SizedBox(height: 12),
          const _ApiTile(
            titulo: 'Noticias RSS',
            subtitulo: 'Fuente de actualidad configurada',
            icono: Icons.rss_feed,
            conectado: true,
          ),
          const SizedBox(height: 12),
          const _ApiTile(
            titulo: 'Google Play Books',
            subtitulo: 'Requiere autenticación',
            icono: Icons.library_books_outlined,
            conectado: false,
          ),
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        activeColor: Theme.of(context).primaryColor,
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitulo,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).primaryColor.withOpacity(0.6),
          ),
        ),
        secondary: Icon(icono, color: Theme.of(context).primaryColor),
        value: valor,
        onChanged: onChanged,
      ),
    );
  }
}

class _ApiTile extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final bool conectado;

  const _ApiTile({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.conectado,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          icono,
          color: conectado ? primaryColor : primaryColor.withOpacity(0.3),
          size: 28,
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitulo,
          style: TextStyle(fontSize: 13, color: primaryColor.withOpacity(0.6)),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: conectado ? primaryColor : primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            conectado ? 'Conectado' : 'Vincular',
            style: TextStyle(
              color: conectado
                  ? Theme.of(context).scaffoldBackgroundColor
                  : primaryColor.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
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
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
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
                            url: volumeInfo['infoLink'],
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
                            url: pdf['link'],
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
                            url:
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
        fillColor: Theme.of(context).primaryColor.withOpacity(0.04),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18.0,
          horizontal: 20.0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
            width: 1.5,
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

class _TarjetaArticulo extends StatelessWidget {
  final String titulo;
  final String fuente;
  final String tiempoLectura;
  final bool isDestacado;
  final String? contenido;
  final String? imageUrl;
  final String? url;

  const _TarjetaArticulo({
    required this.titulo,
    required this.fuente,
    required this.tiempoLectura,
    this.isDestacado = false,
    this.contenido,
    this.imageUrl,
    this.url,
  });

  Future<void> _abrirEnlace(BuildContext context) async {
    if (url != null) {
      final uri = Uri.parse(url!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    // Si no hay URL, se abre en el lector integrado (comportamiento original)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ReaderScreen(titulo: titulo, fuente: fuente, contenido: contenido),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _abrirEnlace(context),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Theme.of(context).primaryColor,
                        height: 1.3, // Interlineado para mejor lectura
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (isDestacado)
                          const Padding(
                            padding: EdgeInsets.only(right: 4.0),
                            child: Icon(
                              Icons.star,
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
                              fontSize: 13,
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
              const SizedBox(width: 16),
              imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.error_outline),
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.article_outlined,
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
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
      appBar: AppBar(title: const Text('Actualidad'), centerTitle: false),
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
                          url: articulo
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

// --- SECCIÓN 3: BIBLIOTECA (Tus PDFs y Libros) ---
class _SeccionBiblioteca extends StatefulWidget {
  const _SeccionBiblioteca();

  @override
  State<_SeccionBiblioteca> createState() => _SeccionBibliotecaState();
}

class _SeccionBibliotecaState extends State<_SeccionBiblioteca> {
  bool _esVistaGrid = false; // Alternador de vistas

  // Muestra el panel interactivo del resumen generado por IA
  Future<void> _mostrarResumenIA(
    BuildContext context,
    Map<String, dynamic> doc,
  ) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.purple[400]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Resumen IA: ${doc['titulo']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FutureBuilder<String>(
                  future: _generarResumen(doc),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                color: Colors.purple[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Analizando primera página...',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Text(
                        'Error al generar resumen: ${snapshot.error}',
                      );
                    } else {
                      return Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            snapshot.data ?? 'Sin resumen.',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.9),
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Motor de extracción rápida de contexto (Extrae solo la pag 1 para no saturar tokens IA)
  Future<String> _generarResumen(Map<String, dynamic> doc) async {
    try {
      String extract = '';
      if (doc['esPdf'] == true && doc['path'] != null) {
        final File file = File(doc['path']);
        final PdfDocument document = PdfDocument(
          inputBytes: file.readAsBytesSync(),
        );
        final PdfTextExtractor extractor = PdfTextExtractor(document);
        // Extraemos solo la primera página para dar contexto eficiente a la IA
        extract = extractor.extractText(startPageIndex: 0, endPageIndex: 0);
        document.dispose();
      } else {
        return 'Solo se pueden resumir documentos PDF locales.';
      }

      final aiService = AiTranslationService();
      return await aiService.getResumen(doc['titulo'], extract);
    } catch (e) {
      return 'No se pudo leer el documento para resumir. Asegúrate de que no esté encriptado o dañado.';
    }
  }

  Future<void> _agregarArchivoLocal({
    required BuildContext context,
    required LibraryProvider provider,
    required bool esPdf,
    required bool esEpub,
    required List<String> extensiones,
  }) async {
    Navigator.pop(context);

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
          'etiqueta': 'Locales',
        };

        await provider.agregarDocumento(nuevoDoc);
      }
    } catch (e) {
      print('Error al seleccionar el archivo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Biblioteca'), centerTitle: false),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).scaffoldBackgroundColor,
        icon: const Icon(Icons.add),
        label: const Text(
          'Añadir',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        elevation: 2,
        onPressed: () {
          // Menú inferior para seleccionar tipo de archivo
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            backgroundColor: Colors.white,
            builder: (bottomSheetContext) => SafeArea(
              child: Wrap(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'Añadir a la biblioteca',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf),
                    title: const Text('Añadir PDF'),
                    onTap: () => _agregarArchivoLocal(
                      context: bottomSheetContext,
                      provider: libraryProvider,
                      esPdf: true,
                      esEpub: false,
                      extensiones: ['pdf'],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.book),
                    title: const Text('Añadir Libro (ePub)'),
                    onTap: () => _agregarArchivoLocal(
                      context: bottomSheetContext,
                      provider: libraryProvider,
                      esPdf: false,
                      esEpub: true,
                      extensiones: ['epub'],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.text_snippet),
                    title: const Text('Añadir Texto (TXT)'),
                    onTap: () => _agregarArchivoLocal(
                      context: bottomSheetContext,
                      provider: libraryProvider,
                      esPdf: false,
                      esEpub: false,
                      extensiones: ['txt'],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        children: [
          // --- TARJETA GOOGLE PLAY BOOKS ---
          Container(
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12), // Redondeado moderado
            ),
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.cloud_download_outlined,
                    color: Colors.blueAccent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buscar en Google Books',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Explora el catálogo mundial y descárgalos.',
                        style: TextStyle(
                          color: Colors.blueAccent.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    // Abre un buscador rápido
                    showDialog(
                      context: context,
                      builder: (context) {
                        final textCtrl = TextEditingController();
                        return AlertDialog(
                          backgroundColor: Theme.of(context).cardColor,
                          title: const Text('Búsqueda Rápida Google Books'),
                          content: TextField(
                            controller: textCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Ej. El Quijote',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cerrar'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final items =
                                    await GoogleBooksService.buscarLibros(
                                      textCtrl.text,
                                    );
                                Navigator.pop(context);
                                if (items.isNotEmpty) {
                                  final primer = items[0]['volumeInfo'];
                                  libraryProvider.agregarDocumento({
                                    'titulo': primer['title'] ?? 'Libro Web',
                                    'descargado': false,
                                    'esPdf': true,
                                    'esEpub': false,
                                    'url': primer['infoLink'] ?? '',
                                    'etiqueta': 'Google Books',
                                  });
                                }
                              },
                              child: const Text('Añadir el mejor resultado'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text(
                    'Explorar',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Carpetas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              IconButton(
                icon: Icon(
                  _esVistaGrid
                      ? Icons.view_list_outlined
                      : Icons.grid_view_outlined,
                ),
                onPressed: () => setState(() => _esVistaGrid = !_esVistaGrid),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: libraryProvider.etiquetasDisponibles.map((etiqueta) {
                final isSelected = libraryProvider.etiquetaActiva == etiqueta;
                final primaryColor = Theme.of(context).primaryColor;
                final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(etiqueta),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        HapticFeedback.selectionClick();
                        libraryProvider.setEtiquetaActiva(etiqueta);
                      }
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
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // --- LISTA ALMACENAMIENTO LOCAL ---
          ...libraryProvider.documentos.map((doc) {
            final isDownloaded = doc['descargado'] as bool;
            final isDownloading = doc['descargando'] ?? false;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.book_outlined,
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
                    isDownloading
                        ? 'Descargando...'
                        : isDownloaded
                        ? 'Disponible offline'
                        : 'Toque para descargar',
                    style: TextStyle(
                      color: isDownloaded
                          ? Theme.of(context).primaryColor.withOpacity(0.6)
                          : Theme.of(context).primaryColor.withOpacity(0.4),
                      fontSize: 13,
                    ),
                  ),
                  trailing: isDownloading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(
                              context,
                            ).primaryColor, // Color coordinado
                          ),
                        )
                      : Icon(
                          isDownloaded
                              ? Icons.check_circle_outline
                              : Icons.arrow_circle_down_outlined,
                          color: isDownloaded
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).primaryColor.withOpacity(0.3),
                          size: 26,
                        ),
                  onLongPress: isDownloaded && doc['esPdf'] == true
                      ? () {
                          HapticFeedback.heavyImpact();
                          _mostrarResumenIA(context, doc);
                        }
                      : null,
                  onTap: isDownloading
                      ? null // Desactiva el toque mientras se descarga
                      : () async {
                          if (isDownloaded && doc['path'] != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReaderScreen(
                                  titulo: doc['titulo'],
                                  fuente:
                                      doc['etiqueta'] ?? 'Almacenamiento Local',
                                  documentPath: doc['path'],
                                  isPdf: doc['esPdf'] ?? false,
                                  isEpub: doc['esEpub'] ?? false,
                                ),
                              ),
                            );
                          } else {
                            // INICIAMOS LA DESCARGA REAL
                            if (doc['url'] != null) {
                              await libraryProvider.descargarDocumento(doc);
                            }
                          }
                        },
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
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
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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
