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
import '../services/local_db_service.dart';

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
    const _SeccionBiblioteca(), // ¡Conectamos la biblioteca real!
    const _SeccionAjustes(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _indiceActual, children: _pantallas),
      // --- BARRA DE NAVEGACIÓN PREMIUM ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor ?? Colors.grey,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _indiceActual,
          onTap: (indice) => setState(() => _indiceActual = indice),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).cardColor,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey[500],
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Explorar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.newspaper_outlined),
              activeIcon: Icon(Icons.newspaper),
              label: 'Noticias',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined),
              activeIcon: Icon(Icons.book),
              label: 'Biblioteca',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Ajustes',
            ),
          ],
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor ?? Colors.grey,
        ),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor ?? Colors.grey,
        ),
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
  String _busquedaActual = 'Objetivos de Desarrollo Sostenible';
  // Inicializamos directamente para evitar errores de LateInitialization en Hot Reload
  late Future<List<dynamic>> _resultadosBusqueda =
      WikipediaService.buscarArticulos(_busquedaActual);

  void _realizarBusqueda(String nuevaBusqueda) {
    if (nuevaBusqueda.trim().isNotEmpty) {
      setState(() {
        _busquedaActual = nuevaBusqueda;
        // Solo volvemos a llamar a la API cuando el usuario hace una nueva búsqueda
        _resultadosBusqueda = WikipediaService.buscarArticulos(_busquedaActual);
      });
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
            '¿Qué quieres aprender hoy?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 24),
          _BuscadorUniversal(onBuscar: _realizarBusqueda),
          const SizedBox(height: 24),
          const _FiltrosCategorias(),
          const SizedBox(height: 36),
          const Text(
            'Resultados de Wikipedia',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<dynamic>>(
            future: _resultadosBusqueda,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('Sin resultados.');
              }
              final articulos = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: articulos.length > 5 ? 5 : articulos.length,
                itemBuilder: (context, index) {
                  final articulo = articulos[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _TarjetaArticulo(
                      titulo: articulo['title'],
                      fuente: 'Wikipedia',
                      tiempoLectura: 'Lectura rápida',
                      contenido:
                          (articulo['snippet'] ?? '') +
                          '\n\n(Puedes leer el artículo completo en Wikipedia).',
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// --- Mantenemos los widgets de _BuscadorUniversal, _FiltrosCategorias y _TarjetaArticulo igual que antes ---
// --- COMPONENTES (WIDGETS) REUTILIZABLES ---

class _BuscadorUniversal extends StatelessWidget {
  final Function(String) onBuscar; // Recibimos la función

  const _BuscadorUniversal({required this.onBuscar});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onSubmitted: onBuscar, // Activa la búsqueda al dar "Enter" en el teclado
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
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).dividerColor ?? Colors.grey,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).dividerColor ?? Colors.grey,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor.withOpacity(0.4),
            width: 1,
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
        onSelected: (bool value) {},
        selectedColor: primaryColor,
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected
                ? primaryColor
                : (Theme.of(context).dividerColor ?? Colors.grey),
          ),
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

  const _TarjetaArticulo({
    required this.titulo,
    required this.fuente,
    required this.tiempoLectura,
    this.isDestacado = false,
    this.contenido,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navegación fluida hacia el Súper Lector
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
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor ?? Colors.grey,
          ),
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
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor ?? Colors.grey,
                  ),
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
  late Future<RssFeed?> _noticiasFuture;
  final NewsFilterService _newsFilterService = NewsFilterService();

  @override
  void initState() {
    super.initState();
    _noticiasFuture = RssService.obtenerNoticias();
  }

  String _categoriaSeleccionada = 'Recientes';
  final List<String> _categorias = [
    'Recientes',
    'Nacional',
    'Internacional',
    'Seguridad',
    'Videojuegos',
    'Tecnología',
  ];

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categorias.length,
              itemBuilder: (context, index) {
                final cat = _categorias[index];
                final isSelected = cat == _categoriaSeleccionada;
                final primaryColor = Theme.of(context).primaryColor;
                final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() => _categoriaSeleccionada = cat);
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
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? primaryColor
                            : (Theme.of(context).dividerColor ?? Colors.grey),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // --- LISTA DE NOTICIAS ---
          Expanded(
            child: FutureBuilder<RssFeed?>(
              future: _noticiasFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return Center(
                    child: Text(
                      'No se pudieron cargar las noticias.',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor.withOpacity(0.6),
                      ),
                    ),
                  );
                }

                final feed = snapshot.data!;
                // Convertimos a lista modificable para poder ordenarla
                var articulos = feed.items.toList();

                // --- LÓGICA DE FILTRADO POR CATEGORÍA ---
                if (_categoriaSeleccionada != 'Recientes') {
                  articulos = articulos.where((articulo) {
                    final tituloStr = (articulo.title ?? '').toLowerCase();
                    final descStr = (articulo.description ?? '').toLowerCase();
                    final busqueda = _categoriaSeleccionada.toLowerCase();

                    return tituloStr.contains(busqueda) ||
                        descStr.contains(busqueda);
                  }).toList();
                }

                // --- NUEVA LÓGICA: ORDENAR POR RELEVANCIA ---
                articulos.sort((a, b) {
                  final textoA = '${a.title ?? ''} ${a.description ?? ''}';
                  final textoB = '${b.title ?? ''} ${b.description ?? ''}';

                  final scoreA = _newsFilterService.evaluateRelevance(textoA);
                  final scoreB = _newsFilterService.evaluateRelevance(textoB);

                  return scoreB.compareTo(
                    scoreA,
                  ); // Orden descendente (Mayor score primero)
                });

                if (articulos.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay noticias para la categoría "$_categoriaSeleccionada".\nIntenta con otra.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor.withOpacity(0.6),
                      ),
                    ),
                  );
                }

                return ListView.builder(
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

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _TarjetaArticulo(
                        titulo: articulo.title ?? 'Sin título',
                        fuente: feed.title ?? 'Noticias',
                        tiempoLectura: 'Reciente',
                        isDestacado: score > 0.8,
                        contenido: cleanDescription,
                      ),
                    );
                  },
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
  final StorageService _storageService = StorageService();

  List<Map<String, dynamic>> _documentos = [];

  @override
  void initState() {
    super.initState();
    _cargarBiblioteca();
  }

  void _cargarBiblioteca() {
    final docsDB = LocalDbService.obtenerDocumentos();
    if (docsDB.isEmpty) {
      // Datos iniciales de prueba si la base de datos está vacía por primera vez
      final datosIniciales = [
        {
          'titulo': 'Guía de Flutter (PDF Demo)',
          'descargado': true,
          'esPdf': true,
          'esEpub': false,
          'path':
              'https://cdn.syncfusion.com/content/PDFViewer/flutter-succinctly.pdf',
        },
        {
          'titulo': 'Diccionario Filosófico',
          'descargado': false,
          'esPdf': true,
          'esEpub': false,
          'path': null,
          'url':
              'https://cdn.syncfusion.com/content/PDFViewer/flutter-succinctly.pdf',
        },
        {
          'titulo': 'El Arte de la Guerra (ePub)',
          'descargado': true,
          'esPdf': false,
          'esEpub': true,
          'path': 'ruta_falsa.epub',
        },
      ];
      for (var doc in datosIniciales) {
        LocalDbService.guardarDocumento(doc);
      }
      setState(() => _documentos = datosIniciales);
    } else {
      setState(() => _documentos = docsDB);
    }
  }

  // Método para abrir el explorador y añadir un archivo a la lista
  Future<void> _agregarArchivoLocal({
    required bool esPdf,
    required bool esEpub,
    required List<String> extensiones,
  }) async {
    // 1. Primero cerramos el menú inferior
    Navigator.pop(context);

    try {
      // 2. Abrimos el explorador nativo
      FilePickerResult? resultado = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensiones,
      );

      // 3. Si el usuario seleccionó un archivo, lo añadimos a nuestra biblioteca
      if (resultado != null && resultado.files.single.path != null) {
        final nuevoDoc = {
          'titulo': resultado.files.single.name,
          'descargado': true, // Como es un archivo local, ya está descargado
          'esPdf': esPdf,
          'esEpub': esEpub,
          'path': resultado.files.single.path,
          'url': null,
        };

        await LocalDbService.guardarDocumento(
          nuevoDoc,
        ); // Guarda permanentemente en Hive

        setState(() {
          _documentos.insert(0, nuevoDoc);
        });
      }
    } catch (e) {
      print('Error al seleccionar el archivo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Biblioteca'), centerTitle: false),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: const Icon(Icons.add),
        onPressed: () {
          // Menú inferior para seleccionar tipo de archivo
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            backgroundColor: Colors.white,
            builder: (context) => SafeArea(
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
                      esPdf: true,
                      esEpub: false,
                      extensiones: ['pdf'],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.book),
                    title: const Text('Añadir Libro (ePub)'),
                    onTap: () => _agregarArchivoLocal(
                      esPdf: false,
                      esEpub: true,
                      extensiones: ['epub'],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.text_snippet),
                    title: const Text('Añadir Texto (TXT)'),
                    onTap: () => _agregarArchivoLocal(
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
              color: Colors.black,
              borderRadius: BorderRadius.circular(12), // Redondeado moderado
            ),
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.library_books,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vincular Google Play Books',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sincroniza tus colecciones y notas.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    print("Iniciando flujo OAuth de Google...");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text(
                    'Conectar',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // --- LISTA ALMACENAMIENTO LOCAL ---
          const Text(
            'Almacenamiento Local',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          ..._documentos.asMap().entries.map((entry) {
            final index = entry.key;
            final doc = entry.value;
            final isDownloaded = doc['descargado'] as bool;
            final isDownloading = doc['descargando'] ?? false;

            return Padding(
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
                  onTap: isDownloading
                      ? null // Desactiva el toque mientras se descarga
                      : () async {
                          if (isDownloaded && doc['path'] != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReaderScreen(
                                  titulo: doc['titulo'],
                                  fuente: 'Almacenamiento Local',
                                  documentPath: doc['path'],
                                  isPdf: doc['esPdf'] ?? false,
                                  isEpub: doc['esEpub'] ?? false,
                                ),
                              ),
                            );
                          } else {
                            // INICIAMOS LA DESCARGA REAL
                            if (doc['url'] != null) {
                              setState(() => doc['descargando'] = true);

                              final newPath = await _storageService
                                  .downloadFileSilently(
                                    doc['url'],
                                    '${doc['titulo'].replaceAll(' ', '_')}.pdf',
                                  );

                              setState(() {
                                doc['descargando'] = false;
                                if (newPath != null) {
                                  doc['descargado'] = true;
                                  doc['path'] = newPath;
                                  LocalDbService.actualizarDocumento(
                                    index,
                                    doc,
                                  ); // Guardar cambio permanentemente
                                }
                              });
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
