import 'package:flutter/material.dart';
import 'package:omnilibrary/screens/reader_screen.dart';
import 'package:omnilibrary/services/wikipedia_service.dart';
import 'package:omnilibrary/services/rss_service.dart';
import '../services/wikipedia_service.dart';
import '../services/rss_service.dart';
import 'package:dart_rss/dart_rss.dart';
import 'package:file_picker/file_picker.dart';

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
    const Center(child: Text('Configuración del Sistema')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _indiceActual, children: _pantallas),
      // --- BARRA DE NAVEGACIÓN PREMIUM ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _indiceActual,
          onTap: (indice) => setState(() => _indiceActual = indice),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey[400],
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

// --- SECCIÓN 1: EXPLORAR (Lo que ya teníamos programado) ---
class _SeccionExplorar extends StatefulWidget {
  const _SeccionExplorar();

  @override
  State<_SeccionExplorar> createState() => _SeccionExplorarState();
}

class _SeccionExplorarState extends State<_SeccionExplorar> {
  String _busquedaActual = 'Objetivos de Desarrollo Sostenible';

  void _realizarBusqueda(String nuevaBusqueda) {
    if (nuevaBusqueda.trim().isNotEmpty) {
      setState(() => _busquedaActual = nuevaBusqueda);
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
            future: WikipediaService.buscarArticulos(_busquedaActual),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Colors.black),
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
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _TarjetaArticulo(
                      titulo: articulos[index]['title'],
                      fuente: 'Wikipedia',
                      tiempoLectura: 'Lectura rápida',
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
        hintStyle: const TextStyle(color: Colors.black45),
        prefixIcon: const Icon(Icons.search, color: Colors.black54),
        filled: true,
        fillColor: Colors.grey[200], // Fondo gris claro, muy estilo iOS
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), // REDONDEADO MODERADO
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Colors.black26,
            width: 1,
          ), // Borde sutil al tocar
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
          _buildChip('Todo', true),
          _buildChip('Wikipedia', false),
          _buildChip('Noticias', false),
          _buildChip('Podcasts', false),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        selected: isSelected,
        onSelected: (bool value) {},
        selectedColor: Colors.black, // Si está seleccionado, es negro sólido
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // REDONDEADO MODERADO
          side: BorderSide(
            color: isSelected
                ? Colors.black
                : Colors.grey[300]!, // Borde gris si no está seleccionado
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

  const _TarjetaArticulo({
    required this.titulo,
    required this.fuente,
    required this.tiempoLectura,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navegación fluida hacia el Súper Lector
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReaderScreen(titulo: titulo, fuente: fuente),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12), // Elegancia moderada
          border: Border.all(
            color: Colors.grey[200]!,
          ), // Borde gris finísimo, sin sombras pesadas
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.3, // Interlineado para mejor lectura
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$fuente • $tiempoLectura',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(
                    8,
                  ), // Redondeado de la imagen
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Icon(
                  Icons.article_outlined,
                  color: Colors.black45,
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
class _SeccionNoticias extends StatelessWidget {
  const _SeccionNoticias();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Actualidad'), centerTitle: false),
      body: FutureBuilder<RssFeed?>(
        future: RssService.obtenerNoticias(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text(
                'No se pudieron cargar las noticias.',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          final feed = snapshot.data!;
          final articulos =
              feed.items; // dart_rss maneja los items directamente

          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            itemCount: articulos.length,
            itemBuilder: (context, index) {
              final articulo = articulos[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _TarjetaArticulo(
                  titulo: articulo.title ?? 'Sin título',
                  fuente: feed.title ?? 'Noticias',
                  tiempoLectura: 'Reciente',
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- SECCIÓN 3: BIBLIOTECA (Tus PDFs y Libros) ---
class _SeccionBiblioteca extends StatefulWidget {
  const _SeccionBiblioteca();

  @override
  State<_SeccionBiblioteca> createState() => _SeccionBibliotecaState();
}

class _SeccionBibliotecaState extends State<_SeccionBiblioteca> {
  // Aquí guardaremos la lista de archivos que el usuario vaya agregando
  List<PlatformFile> _misDocumentos = [];

  // Función para abrir el explorador nativo del celular
  Future<void> _agregarDocumento() async {
    try {
      FilePickerResult? resultado = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'epub',
        ], // Solo permitimos formatos de lectura
        allowMultiple: true, // Permite seleccionar varios a la vez
      );

      if (resultado != null) {
        setState(() {
          // Agregamos los archivos nuevos a nuestra estantería
          _misDocumentos.addAll(resultado.files);
        });
      }
    } catch (e) {
      print("Error al abrir los archivos: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Documentos'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Añadir PDF',
            onPressed: _agregarDocumento,
          ),
        ],
      ),
      // Si la estantería está vacía, mostramos un mensaje amigable
      body: _misDocumentos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tu estantería está vacía',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _agregarDocumento,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Importar PDF o ePub'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black, // Botón negro premium
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          // Si ya hay archivos, los mostramos en formato de lista elegante
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              itemCount: _misDocumentos.length,
              itemBuilder: (context, index) {
                final archivo = _misDocumentos[index];

                // Calculamos el tamaño del archivo para mostrarlo (MB)
                final double tamanoMB = archivo.size / (1024 * 1024);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          archivo.extension == 'pdf'
                              ? Icons.picture_as_pdf_outlined
                              : Icons.book_outlined,
                          color: Colors.black54,
                        ),
                      ),
                      title: Text(
                        archivo.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${archivo.extension!.toUpperCase()} • ${tamanoMB.toStringAsFixed(2)} MB',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.black26,
                      ),
                      onTap: () {
                        // Aquí conectaremos el visor de PDFs nativo
                        print("Abrir archivo: ${archivo.path}");
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
