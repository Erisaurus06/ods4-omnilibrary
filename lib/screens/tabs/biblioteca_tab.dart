import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/local_db_service.dart';
import '../reader_screen.dart';

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

class BibliotecaTab extends StatefulWidget {
  const BibliotecaTab({super.key});
  @override
  State<BibliotecaTab> createState() => _BibliotecaTabState();
}

class _BibliotecaTabState extends State<BibliotecaTab> {
  List<Map<String, dynamic>> _documentos = [];
  bool _vistaCuadricula = false;
  String _searchQuery = '';
  bool _isLoading = true;

  List<Color> _generarColoresPortada(String titulo) {
    final int hash = titulo.hashCode;
    return [
      HSLColor.fromAHSL(1.0, (hash % 360).toDouble(), 0.7, 0.4).toColor(),
      HSLColor.fromAHSL(
        1.0,
        ((hash * 13) % 360).toDouble(),
        0.8,
        0.2,
      ).toColor(),
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

  void _mostrarMenuDocumento(Map<String, dynamic> doc) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(doc['titulo']?.toString() ?? 'Sin título',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              HapticFeedback.selectionClick(); // Regla 5: Haptics
              Navigator.pop(ctx);
              _abrirLector(doc);
            },
            child: const Text('Abrir documento'),
          ),
          if (doc['esPdf'] == true && doc['path'] != null)
            CupertinoActionSheetAction(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.pop(ctx);
              },
              child: const Text('Generar Flashcards con IA'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(ctx);
            _confirmarEliminacion(doc);
          },
          child: const Text('Eliminar documento',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  void _confirmarEliminacion(Map<String, dynamic> doc) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Eliminar Documento'),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${doc['titulo']?.toString() ?? 'este documento'}"?\nEsta acción no se puede deshacer.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: CupertinoColors.systemBlue)),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx);
              _borrarDocumento(doc);
            },
            child: const Text('Eliminar',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _borrarDocumento(Map<String, dynamic> targetDoc) async {
    final raw = LocalDbService.obtenerDocumentos();
    int targetIndex = -1;
    for (int i = 0; i < raw.length; i++) {
      if (raw[i]['path'] == targetDoc['path'] &&
          raw[i]['titulo'] == targetDoc['titulo']) {
        targetIndex = i;
        break;
      }
    }

    // Regla 4: Borrado inmediato del estado para compatibilidad fluida con Dismissible
    if (mounted) {
      setState(() {
        _documentos.removeWhere((d) =>
            d['path'] == targetDoc['path'] &&
            d['titulo'] == targetDoc['titulo']);
      });
    }

    if (targetIndex != -1) {
      await LocalDbService.eliminarDocumento(targetIndex);
    }
    await _cargarBiblioteca();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Documento eliminado',
            style: TextStyle(
              color: Theme.of(context).scaffoldBackgroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Theme.of(context).primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          elevation: 0,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _agregarArchivoLocal({
    required bool esPdf,
    required bool esEpub,
    required List<String> extensiones,
  }) async {
    try {
      FilePickerResult? resultado = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensiones,
      );
      if (resultado != null && resultado.files.single.path != null) {
        await LocalDbService.guardarDocumento({
          'titulo': resultado.files.single.name,
          'descargado': true,
          'esPdf': esPdf,
          'esEpub': esEpub,
          'path': resultado.files.single.path,
          'url': null,
        });
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
            .where((d) => (d['titulo']?.toString() ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          shape: const CircleBorder(),
          elevation: 4,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: const Icon(CupertinoIcons.add),
          onPressed: () {
            HapticFeedback.lightImpact();
            showCupertinoModalPopup(
              context: context,
              builder: (ctx) => CupertinoActionSheet(
                title: const Text('Añadir a mi Biblioteca',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                actions: [
                  CupertinoActionSheetAction(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(ctx);
                      _agregarArchivoLocal(
                        esPdf: true,
                        esEpub: false,
                        extensiones: ['pdf'],
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.doc_text),
                        SizedBox(width: 8),
                        Text('Importar PDF')
                      ],
                    ),
                  ),
                  CupertinoActionSheetAction(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(ctx);
                      _agregarArchivoLocal(
                        esPdf: false,
                        esEpub: true,
                        extensiones: ['epub'],
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.book),
                        SizedBox(width: 8),
                        Text('Importar Libro (ePub)')
                      ],
                    ),
                  ),
                ],
                cancelButton: CupertinoActionSheetAction(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar',
                      style: TextStyle(fontWeight: FontWeight.w600)),
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
            expandedHeight: 140.0,
            floating: true,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: 25, sigmaY: 25), // Regla 1: Cristal Esmerilado
                child: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Text(
                    'Biblioteca',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.0,
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
                        ? CupertinoIcons.list_bullet
                        : CupertinoIcons.square_grid_2x2,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() => _vistaCuadricula = !_vistaCuadricula);
                  }),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: CupertinoSearchTextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                placeholder: 'Buscar en mi biblioteca...',
                style: TextStyle(
                    color: Theme.of(context).primaryColor, fontSize: 17),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                borderRadius: BorderRadius.circular(12),
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
                      CupertinoIcons.book,
                      size: 80,
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        'Tu biblioteca está vacía',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20, // Ajuste iOS
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.6),
                          letterSpacing: -0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        'Toca el botón + para añadir.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.5),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ).animate().fade().scale(),
              ),
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
      padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 140.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final doc = documentos[index];
          return Dismissible(
            key: Key('doc_${doc['path']}_${doc['titulo']}'),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: 12.0),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                color: CupertinoColors.destructiveRed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(CupertinoIcons.delete,
                  color: Colors.white, size: 28),
            ),
            onDismissed: (direction) {
              HapticFeedback.mediumImpact(); // Regla 5
              _borrarDocumento(doc);
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20), // Regla 3: Squarcles
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.04), // Regla 3: Sombra Suave
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        doc['esPdf'] == true
                            ? CupertinoIcons.doc_text
                            : CupertinoIcons.book,
                        color: Theme.of(context).primaryColor.withOpacity(0.6),
                      ),
                    ),
                    title: Text(
                      doc['titulo']?.toString() ?? 'Sin título',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17, // Tamaño nativo de lista iOS
                        letterSpacing: -0.3,
                        color: Theme.of(context).primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Local',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Icon(
                      CupertinoIcons.chevron_right,
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                    onTap: () {
                      HapticFeedback.lightImpact(); // Regla 5
                      _abrirLector(doc);
                    },
                    onLongPress: () {
                      HapticFeedback.selectionClick();
                      _mostrarMenuDocumento(doc);
                    },
                  ),
                ),
              ),
            ),
          ).animate().fade(duration: 300.ms);
        }, childCount: documentos.length),
      ),
    );
  }

  Widget _construirSliverCuadricula(List<Map<String, dynamic>> documentos) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.70,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final doc = documentos[index];
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _abrirLector(doc);
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              _mostrarMenuDocumento(doc);
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _generarColoresPortada(
                    doc['titulo']?.toString() ?? 'Sin título',
                  ),
                ),
                borderRadius: BorderRadius.circular(20), // Regla 3: Squarcles
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04), // Regla 3
                    blurRadius: 20,
                    offset: const Offset(0, 8),
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
                          ? CupertinoIcons.doc_text_fill
                          : CupertinoIcons.book_fill,
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
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              doc['titulo']?.toString() ?? 'Sin título',
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fade(duration: 400.ms).scale(
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
            titulo: doc['titulo']?.toString() ?? 'Sin título',
            fuente: 'Mi Biblioteca',
            documentPath: doc['path']?.toString(),
            isPdf: doc['esPdf'] == true,
            isEpub: doc['esEpub'] == true,
          ),
        ),
      );
    }
  }
}
