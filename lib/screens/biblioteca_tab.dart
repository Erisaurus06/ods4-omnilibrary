import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/local_db_service.dart';
import 'reader_screen.dart';
import '../services/ai_translation_service.dart';

List<Map<String, dynamic>> _procesarDocumentosEnFondo(
  List<Map<String, dynamic>> rawData,
) {
  final docs = List<Map<String, dynamic>>.from(rawData);
  docs.sort(
    (a, b) => (a['titulo'] ?? '').toString().compareTo(
      (b['titulo'] ?? '').toString(),
    ),
  );
  return docs;
}

class SeccionBiblioteca extends StatefulWidget {
  const SeccionBiblioteca({super.key});

  @override
  State<SeccionBiblioteca> createState() => _SeccionBibliotecaState();
}

class _SeccionBibliotecaState extends State<SeccionBiblioteca> {
  List<Map<String, dynamic>> _documentos = [];
  bool _vistaCuadricula = false;
  String _searchQuery = '';
  bool _isLoading = true;

  List<Color> _generarColoresPortada(String titulo) {
    final int hash = titulo.hashCode;
    final hue1 = (hash % 360).toDouble();
    final hue2 = ((hash * 13) % 360).toDouble();
    return [
      HSLColor.fromAHSL(1.0, hue1, 0.7, 0.4).toColor(),
      HSLColor.fromAHSL(1.0, hue2, 0.8, 0.2).toColor(),
    ];
  }

  @override
  void initState() {
    super.initState();
    _cargarBiblioteca();
  }

  Future<void> _cargarBiblioteca() async {
    await Future.delayed(const Duration(milliseconds: 250));
    final raw = LocalDbService.obtenerDocumentos();
    final procesado = await compute(_procesarDocumentosEnFondo, raw);
    if (mounted) {
      setState(() {
        _documentos = procesado;
        _isLoading = false;
      });
    }
  }

  void _mostrarMenuDocumento(int index) {
    final doc = _documentos[index];
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                doc['titulo'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Abrir documento'),
              onTap: () {
                Navigator.pop(context);
                _abrirLector(doc);
              },
            ),
            if (doc['esPdf'] == true && doc['path'] != null) ...[
              ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: const Text('Generar Flashcards con IA'),
                onTap: () {
                  Navigator.pop(context);
                  _generarFlashcardsDesdePdf(doc['path'] as String);
                },
              ),
              ListTile(
                leading: const Icon(Icons.summarize_outlined),
                title: const Text('Resumir PDF con IA'),
                onTap: () {
                  Navigator.pop(context);
                  _resumirPdfConIA(
                    doc['path'] as String,
                    doc['titulo'] as String,
                  );
                },
              ),
            ],
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(context);
                _borrarDocumento(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generarFlashcardsDesdePdf(String path) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Extracción de PDF desactivada temporalmente.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _resumirPdfConIA(String path, String titulo) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Extracción de PDF desactivada temporalmente.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _borrarDocumento(int index) async {
    await LocalDbService.eliminarDocumento(index);
    _cargarBiblioteca();
    if (mounted)
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

  Future<void> _agregarArchivoLocal({
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
        final nuevoDoc = <String, dynamic>{
          'titulo': resultado.files.single.name,
          'descargado': true,
          'esPdf': esPdf,
          'esEpub': esEpub,
          'path': resultado.files.single.path,
          'url': null,
        };
        await LocalDbService.guardarDocumento(nuevoDoc);
        _cargarBiblioteca();
      }
    } catch (e) {
      print('Error al seleccionar el archivo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final docsFiltrados = _searchQuery.isEmpty
        ? _documentos
        : _documentos
              .where(
                (d) => (d['titulo'] ?? '').toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child:
            FloatingActionButton(
              shape: const CircleBorder(),
              elevation: 4,
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: const Icon(Icons.add),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
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
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
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
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
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
            ).animate().scale(
              delay: 200.ms,
              duration: 400.ms,
              curve: Curves.easeOutBack,
            ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            backgroundColor: Theme.of(
              context,
            ).scaffoldBackgroundColor.withOpacity(0.9),
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Text(
                    'Biblioteca',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1.2,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _vistaCuadricula
                      ? Icons.view_list_rounded
                      : Icons.grid_view_rounded,
                  color: Theme.of(context).primaryColor,
                ),
                tooltip: 'Cambiar vista',
                onPressed: () =>
                    setState(() => _vistaCuadricula = !_vistaCuadricula),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade800.withOpacity(0.6)
                          : Colors.grey.shade300.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search, color: Colors.grey, size: 20),
                        hintText: 'Buscar en mi biblioteca...',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                  strokeWidth: 2,
                ).animate().fade(duration: 400.ms),
              ),
            )
          else if (_documentos.isEmpty)
            SliverFillRemaining(
              child: Center(
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
              ).animate().fade().scale(),
            )
          else if (_vistaCuadricula)
            _construirSliverCuadricula(docsFiltrados)
          else
            _construirSliverLista(docsFiltrados),
        ],
      ),
    );
  }

  Widget _construirSliverLista(List<Map<String, dynamic>> documentos) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final doc = documentos[index];
          final realIndex = _documentos.indexOf(doc);
          return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
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
                    onLongPress: () => _mostrarMenuDocumento(realIndex),
                  ),
                ),
              )
              .animate()
              .fade(duration: 300.ms)
              .slideX(begin: 0.05, end: 0, delay: (index % 15 * 30).ms);
        }, childCount: documentos.length),
      ),
    );
  }

  Widget _construirSliverCuadricula(List<Map<String, dynamic>> documentos) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.70,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final doc = documentos[index];
          final realIndex = _documentos.indexOf(doc);
          return GestureDetector(
                onTap: () => _abrirLector(doc),
                onLongPress: () => _mostrarMenuDocumento(realIndex),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _generarColoresPortada(doc['titulo']),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.antiAlias,
                    children: [
                      Positioned(
                        right: -15,
                        bottom: -15,
                        child: Icon(
                          doc['esPdf'] == true
                              ? Icons.picture_as_pdf
                              : Icons.menu_book,
                          size: 90,
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                doc['esPdf'] == true ? 'PDF' : 'EPUB',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              doc['titulo'],
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .fade(duration: 400.ms)
              .scale(
                begin: const Offset(0.9, 0.9),
                delay: (index % 10 * 40).ms,
              );
        }, childCount: documentos.length),
      ),
    );
  }

  void _abrirLector(Map<String, dynamic> doc) {
    if (doc['path'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReaderScreen(
            titulo: doc['titulo'] as String,
            fuente: 'Mi Biblioteca',
            documentPath: doc['path'] as String?,
            isPdf: doc['esPdf'] as bool? ?? false,
            isEpub: doc['esEpub'] as bool? ?? false,
          ),
        ),
      );
    }
  }
}
