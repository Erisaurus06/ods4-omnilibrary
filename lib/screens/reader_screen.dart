import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:epub_view/epub_view.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/local_db_service.dart';
import '../services/dictionary_service.dart';

class ReaderScreen extends StatefulWidget {
  final String titulo;
  final String fuente;
  final String? documentPath;
  final String? contenido;
  final bool isPdf;
  final bool isEpub;

  const ReaderScreen({
    super.key,
    required this.titulo,
    required this.fuente,
    this.documentPath,
    this.contenido,
    this.isPdf = false,
    this.isEpub = false,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  // Variables para controlar la experiencia de lectura
  double _fontSize = 18.0;
  late Color _backgroundColor;
  late Color _textColor;
  EpubController? _epubController;
  bool _temaInicializado = false;

  // Nuevos estados para funcionalidades avanzadas
  double _brillo = 1.0;
  String _modoVista =
      'Lineal'; // Modos: Lineal, Libre, Manga, Dos Hojas, Desparramado
  bool _modoTraduccion = false;
  String _fontFamily = 'System'; // Tipografía activa

  // --- NUEVAS VARIABLES PARA EL PROGRESO ---
  final PdfViewerController _pdfViewerController = PdfViewerController();
  int _paginaGuardadaPdf = 1;
  String? _cfiGuardadoEpub;
  bool _cargandoProgreso = true; // Pantalla de carga mientras lee la memoria

  // --- NUEVAS VARIABLES PARA TEXT-TO-SPEECH ---
  final GlobalKey<SfPdfViewerState> _pdfViewerKey =
      GlobalKey(); // Llave para guardar el PDF
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  // Función para cambiar el tema de lectura
  void _cambiarTema(String tema) {
    setState(() {
      if (tema == 'Blanco') {
        _backgroundColor = const Color(0xFFFFFFFF); // Blanco puro
        _textColor = Colors.black87;
      } else if (tema == 'Amarillo') {
        _backgroundColor = const Color(0xFFFBF0D9); // Sepia elegante (Yellow)
        _textColor = Colors.black87;
      } else if (tema == 'Negro') {
        _backgroundColor = const Color(0xFF000000); // Negro OLED
        _textColor = Colors.white70; // Blanco suave tenue
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_temaInicializado) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      _backgroundColor = isDark
          ? const Color(0xFF121212)
          : const Color(0xFFFAFAFA);
      _textColor = isDark ? Colors.white70 : Colors.black87;
      _temaInicializado = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _initBrightness();
    _inicializarLectura();
    _initTts();
  }

  void _initTts() {
    // Configuramos el idioma y la velocidad por defecto
    _flutterTts.setLanguage("es-MX"); // Español de México / Latino
    _flutterTts.setSpeechRate(0.5); // Velocidad moderada

    // Escuchamos cuando la lectura ha finalizado para reiniciar el ícono
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    });
  }

  Future<void> _inicializarLectura() async {
    if (widget.documentPath != null) {
      if (widget.isPdf) {
        _paginaGuardadaPdf =
            LocalDbService.obtenerProgreso('pdf_page_${widget.documentPath}') ??
            1;
      } else if (widget.isEpub) {
        _cfiGuardadoEpub = LocalDbService.obtenerProgreso(
          'epub_cfi_${widget.documentPath}',
        );
        final file = File(widget.documentPath!);
        if (file.existsSync()) {
          _epubController = EpubController(
            document: EpubDocument.openFile(file),
            epubCfi:
                _cfiGuardadoEpub, // ePubView soporta abrir directo en una posición
          );
        }
      }
    }

    setState(() {
      _cargandoProgreso = false;
    });
  }

  Future<void> _initBrightness() async {
    try {
      final currentBrightness = await ScreenBrightness().current;
      setState(() {
        _brillo = currentBrightness;
      });
    } catch (e) {
      print('No se pudo obtener el brillo de la pantalla: $e');
    }
  }

  @override
  void dispose() {
    ScreenBrightness().resetScreenBrightness();
    _flutterTts.stop(); // Detenemos la voz si el usuario cierra el lector
    _guardarProgresoEpub(); // Guardamos el ePub justo al salir
    _epubController?.dispose();
    _pdfViewerController.dispose();
    super.dispose();
  }

  void _guardarProgresoEpub() {
    if (widget.isEpub &&
        _epubController != null &&
        widget.documentPath != null) {
      try {
        final cfi = _epubController!
            .generateEpubCfi(); // Obtiene posición exacta
        if (cfi != null) {
          LocalDbService.guardarProgreso(
            'epub_cfi_${widget.documentPath}',
            cfi,
          );
        }
      } catch (e) {
        print("No se pudo guardar el progreso del ePub: $e");
      }
    }
  }

  // --- GUARDADO DE ANOTACIONES PDF ---
  Future<void> _guardarAnotacionesPdf() async {
    // Solo permitimos guardar si es un archivo local (no de internet)
    if (widget.isPdf &&
        widget.documentPath != null &&
        !widget.documentPath!.startsWith('http')) {
      try {
        // Extraemos los bytes del PDF con las nuevas anotaciones hechas en pantalla
        final List<int> documentBytes = await _pdfViewerController
            .saveDocument();

        // Sobrescribimos el archivo local
        final File file = File(widget.documentPath!);
        await file.writeAsBytes(documentBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Anotaciones guardadas correctamente.',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
            backgroundColor: Theme.of(context).cardColor,
          ),
        );
      } catch (e) {
        print("Error al guardar anotaciones en PDF: $e");
      }
    }
  }

  Future<void> _toggleTts() async {
    if (_isSpeaking) {
      // Si está hablando, lo silenciamos
      await _flutterTts.stop();
      setState(() => _isSpeaking = false);
    } else {
      // Si está callado, comenzamos la lectura del contenido
      final textoAleer =
          widget.contenido ??
          'La educación es el arma más poderosa que puedes usar para cambiar el mundo.\n\nEl acceso a la información siempre ha sido un pilar fundamental para el desarrollo humano. Sin embargo, en la era digital, nos enfrentamos a un nuevo reto: la sobreinformación y la fragmentación del conocimiento.';

      // Removemos posibles saltos de línea raros para que la voz fluya natural
      final textoLimpio = textoAleer.replaceAll('\n\n', ' . ');

      await _flutterTts.speak(textoLimpio);
      setState(() => _isSpeaking = true);
    }
  }

  // --- DICCIONARIO OFFLINE (SIMULADO) ---
  void _mostrarDefinicion(String palabra) async {
    if (palabra.isEmpty) return;

    // Limpiamos la palabra de signos de puntuación y la pasamos a minúsculas
    final palabraLimpia = palabra
        .replaceAll(RegExp(r'[^\w\sáéíóúÁÉÍÓÚñÑ]'), '')
        .toLowerCase()
        .trim();

    // Llamamos al servicio real para obtener la definición
    String definicion = 'Buscando definición...';
    try {
      definicion = await DictionaryService.definirPalabra(palabraLimpia);
    } catch (e) {
      definicion = 'Error al consultar el diccionario online.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _backgroundColor,
        title: Text(
          palabra,
          style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          definicion,
          style: TextStyle(color: _textColor.withOpacity(0.9), fontSize: 16),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Entendido',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  // --- GUARDADO DE CITAS FAVORITAS ---
  Future<void> _guardarCita(String cita) async {
    if (cita.isEmpty) return;

    final nuevaCita = '«$cita»\n— ${widget.titulo}';
    await LocalDbService.guardarCita(nuevaCita);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cita guardada en favoritos ⭐',
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
          backgroundColor: Theme.of(context).cardColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _mostrarCitasFavoritas() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            List<String> citas = LocalDbService.obtenerCitas();

            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Mis Citas Favoritas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                    ),
                    Divider(color: Colors.grey.withOpacity(0.3)),
                    if (citas.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          'Aún no has guardado ninguna cita.',
                          style: TextStyle(color: _textColor.withOpacity(0.6)),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: citas.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: Icon(
                                Icons.format_quote,
                                color: Theme.of(context).primaryColor,
                              ),
                              title: Text(
                                citas[index],
                                style: TextStyle(
                                  color: _textColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red[300],
                                ),
                                onPressed: () {
                                  LocalDbService.eliminarCita(index);
                                  setModalState(() {});
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Menú inferior avanzado
  void _mostrarAjustesAvanzados() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return StatefulBuilder(
          // StatefulBuilder para actualizar el Modal
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ajustes Avanzados',
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Control de Brillo Aislado (screen_brightness)
                    Row(
                      children: [
                        Icon(
                          Icons.brightness_low_outlined,
                          color: Theme.of(context).primaryColor,
                        ),
                        Expanded(
                          child: Slider(
                            value: _brillo,
                            activeColor: Theme.of(context).primaryColor,
                            onChanged: (val) {
                              setModalState(() => _brillo = val);
                              setState(() => _brillo = val);
                              ScreenBrightness().setScreenBrightness(val);
                            },
                          ),
                        ),
                        Icon(
                          Icons.brightness_high_outlined,
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Modos de Animación y Vista
                    Text(
                      'Modo de Visualización',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            [
                              'Lineal (Scroll)',
                              'Libre (Páginas)',
                              'Manga (R to L)',
                              'Dos Hojas',
                              'Desparramado',
                            ].map((modo) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(modo),
                                  selected: _modoVista == modo,
                                  selectedColor: Theme.of(context).primaryColor,
                                  labelStyle: TextStyle(
                                    color: _modoVista == modo
                                        ? Colors.white
                                        : Theme.of(context).primaryColor,
                                  ),
                                  backgroundColor: Theme.of(context).cardColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).dividerColor.withOpacity(0.2),
                                    ),
                                  ),
                                  onSelected: (sel) {
                                    setModalState(() => _modoVista = modo);
                                    setState(() => _modoVista = modo);
                                  },
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Control de Tipografía y Tamaño
                    Text(
                      'Tipografía',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _fontFamily,
                            dropdownColor: Theme.of(context).cardColor,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).dividerColor.withOpacity(0.2),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).dividerColor.withOpacity(0.2),
                                ),
                              ),
                            ),
                            items:
                                ['System', 'Serif', 'Sans Serif', 'Monospace']
                                    .map(
                                      (f) => DropdownMenuItem(
                                        value: f,
                                        child: Text(f),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => _fontFamily = val);
                                setState(() => _fontFamily = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).dividerColor.withOpacity(0.2),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.remove,
                                  color: Theme.of(context).primaryColor,
                                ),
                                onPressed: () {
                                  setModalState(
                                    () => _fontSize = (_fontSize > 12)
                                        ? _fontSize - 2
                                        : 12,
                                  );
                                  setState(
                                    () => _fontSize = (_fontSize > 12)
                                        ? _fontSize - 2
                                        : 12,
                                  );
                                },
                              ),
                              Text(
                                '${_fontSize.toInt()}',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.add,
                                  color: Theme.of(context).primaryColor,
                                ),
                                onPressed: () {
                                  setModalState(
                                    () => _fontSize = (_fontSize < 32)
                                        ? _fontSize + 2
                                        : 32,
                                  );
                                  setState(
                                    () => _fontSize = (_fontSize < 32)
                                        ? _fontSize + 2
                                        : 32,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _textColor),
        actions: [
          if (!widget.isPdf && !widget.isEpub)
            IconButton(
              icon: Icon(
                _isSpeaking
                    ? Icons.stop_circle_outlined
                    : Icons.volume_up_outlined,
              ),
              onPressed: _toggleTts,
            ),
          // Botón de guardado, solo visible para PDFs locales
          if (widget.isPdf &&
              widget.documentPath != null &&
              !widget.documentPath!.startsWith('http'))
            IconButton(
              icon: const Icon(Icons.save_outlined),
              tooltip: 'Guardar anotaciones',
              onPressed: _guardarAnotacionesPdf,
            ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: _mostrarCitasFavoritas, // Abre el menú de favoritos
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // Lógica para compartir
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune), // Botón de ajustes avanzados
            onPressed: _mostrarAjustesAvanzados,
          ),
        ],
      ),
      // BARRA INFERIOR DE CONTROLES (Minimalista)
      // Ocultamos los controles si es un PDF, ya que manejan su propio flujo.
      bottomNavigationBar: widget.isPdf
          ? null
          : Container(
              decoration: BoxDecoration(
                color: _backgroundColor,
                border: Border(
                  top: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Controles de tamaño de letra
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.text_decrease, color: _textColor),
                          onPressed: () => setState(
                            () => _fontSize = (_fontSize > 14)
                                ? _fontSize - 2
                                : 14,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.text_increase, color: _textColor),
                          onPressed: () => setState(
                            () => _fontSize = (_fontSize < 30)
                                ? _fontSize + 2
                                : 30,
                          ),
                        ),
                      ],
                    ),
                    // Controles de color de fondo
                    Row(
                      children: [
                        _ColorButton(
                          color: const Color(0xFFFFFFFF),
                          onTap: () => _cambiarTema('Blanco'),
                        ),
                        const SizedBox(width: 12),
                        _ColorButton(
                          color: const Color(0xFFFBF0D9), // Botón Sepia
                          onTap: () => _cambiarTema('Amarillo'),
                        ),
                        const SizedBox(width: 12),
                        _ColorButton(
                          color: const Color(0xFF000000), // OLED Botón
                          onTap: () => _cambiarTema('Negro'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      // CUERPO DEL ARTÍCULO
      body: _cargandoProgreso
          ? Center(child: CircularProgressIndicator(color: _textColor))
          : widget.isPdf && widget.documentPath != null
          ? _buildPdfViewer()
          : widget.isEpub && widget.documentPath != null
          ? _buildEpubViewer()
          : _buildTextArticle(),
    );
  }

  Widget _buildTextArticle() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.fuente.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: _textColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.titulo,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 24),
          SelectableText(
            widget.contenido ??
                'La educación es el arma más poderosa que puedes usar para cambiar el mundo.\n\nEl acceso a la información siempre ha sido un pilar fundamental para el desarrollo humano. Sin embargo, en la era digital, nos enfrentamos a un nuevo reto: la sobreinformación y la fragmentación del conocimiento.',
            style: TextStyle(
              fontFamily: _fontFamily == 'System' ? null : _fontFamily,
              fontSize: _fontSize,
              height: 1.6, // Interlineado amplio para lectura cómoda
              color: _textColor.withOpacity(0.9),
            ),
            contextMenuBuilder:
                (BuildContext context, EditableTextState editableTextState) {
                  final List<ContextMenuButtonItem> buttonItems =
                      editableTextState.contextMenuButtonItems;

                  // Insertamos nuestro botón de "Definir" al inicio del menú nativo
                  buttonItems.insert(
                    0,
                    ContextMenuButtonItem(
                      label: '📖 Definir',
                      onPressed: () {
                        final textEditingValue =
                            editableTextState.textEditingValue;
                        final selectedText = textEditingValue.selection
                            .textInside(textEditingValue.text)
                            .trim();

                        ContextMenuController.removeAny(); // Cerramos el menú flotante
                        _mostrarDefinicion(
                          selectedText,
                        ); // Mostramos el globo de diccionario
                      },
                    ),
                  );

                  // Insertamos nuestro botón de "Guardar Cita"
                  buttonItems.insert(
                    1,
                    ContextMenuButtonItem(
                      label: '⭐ Guardar Cita',
                      onPressed: () {
                        final textEditingValue =
                            editableTextState.textEditingValue;
                        final selectedText = textEditingValue.selection
                            .textInside(textEditingValue.text)
                            .trim();

                        ContextMenuController.removeAny();
                        _guardarCita(selectedText);
                      },
                    ),
                  );

                  return AdaptiveTextSelectionToolbar.buttonItems(
                    anchors: editableTextState.contextMenuAnchors,
                    buttonItems: buttonItems,
                  );
                },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
    // 1. Lógica para los Modos de Visualización del PDF
    PdfScrollDirection scrollDirection = PdfScrollDirection.vertical;
    PdfPageLayoutMode pageLayoutMode = PdfPageLayoutMode.continuous;

    if (_modoVista == 'Libre (Páginas)') {
      pageLayoutMode = PdfPageLayoutMode.single;
    } else if (_modoVista == 'Manga (R to L)' ||
        _modoVista == 'Dos Hojas' ||
        _modoVista == 'Desparramado') {
      // El modo Manga y Dos hojas típicamente utilizan un desplazamiento horizontal paginado
      scrollDirection = PdfScrollDirection.horizontal;
      pageLayoutMode = PdfPageLayoutMode.single;
    }

    // Verificamos si es un PDF online (para la simulación) o un archivo descargado localmente
    if (widget.documentPath!.startsWith('http')) {
      return SfPdfViewer.network(
        widget.documentPath!,
        key: _pdfViewerKey,
        controller: _pdfViewerController,
        scrollDirection: scrollDirection,
        pageLayoutMode: pageLayoutMode,
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          if (_paginaGuardadaPdf > 1)
            _pdfViewerController.jumpToPage(_paginaGuardadaPdf);
        },
        onPageChanged: (PdfPageChangedDetails details) {
          LocalDbService.guardarProgreso(
            'pdf_page_${widget.documentPath}',
            details.newPageNumber,
          );
        },
      );
    }
    return SfPdfViewer.file(
      File(widget.documentPath!),
      key: _pdfViewerKey,
      controller: _pdfViewerController,
      scrollDirection: scrollDirection,
      pageLayoutMode: pageLayoutMode,
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        if (_paginaGuardadaPdf > 1)
          _pdfViewerController.jumpToPage(_paginaGuardadaPdf);
      },
      onPageChanged: (PdfPageChangedDetails details) {
        LocalDbService.guardarProgreso(
          'pdf_page_${widget.documentPath}',
          details.newPageNumber,
        );
      },
    );
  }

  Widget _buildEpubViewer() {
    if (_epubController == null) {
      // Mensaje elegante y monocromático si el archivo aún no existe localmente
      return Center(
        child: Text(
          'El archivo ePub no se encuentra localmente.\nPor favor descárgalo desde tu biblioteca.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _textColor.withOpacity(0.6), fontSize: 16),
        ),
      );
    }

    return EpubView(controller: _epubController!);
  }
}

// Widget auxiliar para los botones redondos de color
class _ColorButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _ColorButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
        ),
      ),
    );
  }
}
