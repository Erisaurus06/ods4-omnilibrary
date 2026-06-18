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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            color: Theme.of(context).cardColor.withOpacity(0.85),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        doc['titulo']?.toString() ?? 'Sin título',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(CupertinoIcons.book),
                      title: const Text('Abrir documento'),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                        _abrirLector(doc);
                      },
                    ),
                    if (doc['esPdf'] == true && doc['path'] != null) ...[
                      ListTile(
                        leading: const Icon(CupertinoIcons.sparkles),
                        title: const Text('Generar Flashcards con IA'),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                    ListTile(
                      leading: const Icon(CupertinoIcons.delete,
                          color: CupertinoColors.destructiveRed),
                      title: const Text('Eliminar',
                          style: TextStyle(
                              color: CupertinoColors.destructiveRed,
                              fontWeight: FontWeight.bold)),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                        _borrarDocumento(doc);
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
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
    if (targetIndex != -1) {
      await LocalDbService.eliminarDocumento(targetIndex);
    }
    await _cargarBiblioteca();
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
    Navigator.pop(context);
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
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) => ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    color: Theme.of(context).cardColor.withOpacity(0.85),
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: SafeArea(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics()),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 12),
                            Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(10)),
                            ),
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
                                CupertinoIcons.doc_text,
                                color: Theme.of(context).primaryColor,
                              ),
                              title: Text(
                                'Añadir PDF',
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor),
                              ),
                              onTap: () => _agregarArchivoLocal(
                                esPdf: true,
                                esEpub: false,
                                extensiones: ['pdf'],
                              ),
                            ),
                            ListTile(
                              leading: Icon(
                                CupertinoIcons.book,
                                color: Theme.of(context).primaryColor,
                              ),
                              title: Text(
                                'Añadir Libro (ePub)',
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor),
                              ),
                              onTap: () => _agregarArchivoLocal(
                                esPdf: false,
                                esEpub: true,
                                extensiones: ['epub'],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
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
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
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
                        icon: Icon(CupertinoIcons.search,
                            color: CupertinoColors.systemGrey, size: 20),
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
                      CupertinoIcons.book,
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
                      'Toca el botón + para añadir.',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor.withOpacity(0.4),
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
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
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
                    borderRadius: BorderRadius.circular(10),
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
                    fontSize: 15,
                    color: Theme.of(context).primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Local',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
                trailing: Icon(
                  CupertinoIcons.chevron_right,
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _abrirLector(doc);
                },
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  _mostrarMenuDocumento(doc);
                },
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
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
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
                                fontWeight: FontWeight.bold,
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
