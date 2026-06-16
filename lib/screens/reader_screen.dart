import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:epub_view/epub_view.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../services/local_db_service.dart';
import '../services/dictionary_service.dart';
import '../services/ai_translation_service.dart';
import '../services/wikipedia_service.dart';

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
  String _modoVista = 'Vertical (Arriba/Abajo)'; // Opciones actualizadas
  final bool _modoTraduccion = false;
  String _fontFamily = 'System'; // Tipografía activa
  bool _showUI = true; // Control del Modo Inmersivo

  // Nuevas variables para herramientas y temporizador
  Timer? _readingTimer;
  int _timerMinutes = 0;
  Color _highlightColor = Colors.transparent;
  bool _drawMode = false;
  bool _noteMode = false;

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

  // --- NUEVAS VARIABLES PARA DIBUJO/RESALTADO ---
  final List<_Trazo> _trazos = [];
  _Trazo? _trazoActual;
  final ValueNotifier<int> _trazosUpdater = ValueNotifier<int>(
    0,
  ); // Optimizador de dibujo

  // --- NUEVAS VARIABLES: POMODORO Y DICCIONARIO ---
  int _pomodoroSeconds = 0;
  bool _isPomodoroActive = false;
  bool _isPomodoroBreak = false;
  Timer? _pomodoroTimer;

  String? _selectedPdfText; // Guarda el texto seleccionado en el PDF

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
        final dynamic progreso = LocalDbService.obtenerProgreso(
          'pdf_page_${widget.documentPath}',
        );
        _paginaGuardadaPdf = (progreso is num) ? progreso.toInt() : 1;
      } else if (widget.isEpub) {
        _cfiGuardadoEpub = LocalDbService.obtenerProgreso(
          'epub_cfi_${widget.documentPath}',
        );
        final file = File(widget.documentPath!);
        if (file.existsSync()) {
          final epubBytes = await file.readAsBytes();
          _epubController = EpubController(
            document: EpubDocument.openData(epubBytes),
            epubCfi:
                _cfiGuardadoEpub, // ePubView soporta abrir directo en una posición
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _cargandoProgreso = false;
      });
    }
  }

  Future<void> _initBrightness() async {
    try {
      final currentBrightness = await ScreenBrightness().current;
      setState(() {
        _brillo = currentBrightness;
      });
    } catch (e) {
      print('No se pudo obtener el brillo de la pantalla: $e\n');
    }
  }

  void _iniciarTemporizador(int minutos) {
    _readingTimer?.cancel();
    setState(() => _timerMinutes = minutos);

    if (minutos > 0) {
      _readingTimer = Timer(Duration(minutes: minutos), () {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: Text(
                '¡Tiempo cumplido!',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
              content: Text(
                'Tu temporizador de lectura de $minutos minutos ha finalizado.',
                style: TextStyle(
                  color: Theme.of(context).primaryColor.withOpacity(0.8),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Aceptar'),
                ),
              ],
            ),
          );
          setState(() => _timerMinutes = 0);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Temporizador programado: $minutos min.',
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
          backgroundColor: Theme.of(context).cardColor,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Temporizador desactivado.',
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
          backgroundColor: Theme.of(context).cardColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // --- LÓGICA DE POMODORO ---
  void _togglePomodoro() {
    if (_isPomodoroActive) {
      _pomodoroTimer?.cancel();
      setState(() {
        _isPomodoroActive = false;
        _pomodoroSeconds = 0;
      });
    } else {
      setState(() {
        _isPomodoroActive = true;
        _isPomodoroBreak = false;
        _pomodoroSeconds = 25 * 60; // 25 minutos
      });
      _startPomodoroTick();
    }
  }

  void _startPomodoroTick() {
    _pomodoroTimer?.cancel();
    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_pomodoroSeconds > 0) {
          _pomodoroSeconds--;
        } else {
          _isPomodoroBreak = !_isPomodoroBreak;
          _pomodoroSeconds = _isPomodoroBreak ? 5 * 60 : 25 * 60;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isPomodoroBreak ? '¡Tiempo de Descanso! ☕' : '¡A Estudiar! 📖',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              backgroundColor: _isPomodoroBreak
                  ? Colors.green
                  : Colors.redAccent,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    ScreenBrightness().resetScreenBrightness();
    _readingTimer?.cancel();
    _pomodoroTimer?.cancel();
    _flutterTts.stop(); // Detenemos la voz si el usuario cierra el lector
    _guardarProgresoEpub(); // Guardamos el ePub justo al salir
    if (widget.isPdf && widget.documentPath != null) {
      LocalDbService.guardarProgreso(
        'pdf_page_${widget.documentPath}',
        _pdfViewerController.pageNumber,
      );
    }
    _epubController?.dispose();
    _pdfViewerController.dispose();
    _trazosUpdater.dispose();
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

        // Advertencia si el modo de dibujo estaba activo, para gestionar expectativas.
        if (_drawMode && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Nota: Los dibujos a mano alzada aún no se guardan en el PDF.',
              ),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Anotaciones guardadas correctamente.',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
              backgroundColor: Theme.of(context).cardColor,
            ),
          );
        }
      } catch (e) {
        print("Error al guardar anotaciones en PDF: $e");
      }
    }
  }

  Future<void> _toggleTts() async {
    if (_isSpeaking) {
      // Si está hablando, lo silenciamos
      await _flutterTts.stop();
      if (!mounted) return;
      setState(() => _isSpeaking = false);
    } else {
      // Si está callado, comenzamos la lectura del contenido
      final textoAleer =
          widget.contenido ??
          'La educación es el arma más poderosa que puedes usar para cambiar el mundo.\n\nEl acceso a la información siempre ha sido un pilar fundamental para el desarrollo humano. Sin embargo, en la era digital, nos enfrentamos a un nuevo reto: la sobreinformación y la fragmentación del conocimiento.';

      // Removemos posibles saltos de línea raros para que la voz fluya natural
      final textoLimpio = textoAleer.replaceAll('\n\n', ' . ');

      await _flutterTts.speak(textoLimpio);
      if (!mounted) return;
      setState(() => _isSpeaking = true);
    }
  }

  // --- DICCIONARIO MÁGICO (CON WIKIPEDIA) ---
  void _mostrarDefinicion(String palabra) async {
    if (palabra.isEmpty) return;

    // Limpiamos la palabra de signos de puntuación y la pasamos a minúsculas
    final palabraLimpia = palabra
        .replaceAll(RegExp(r'[^\w\sáéíóúÁÉÍÓÚñÑ]'), '')
        .toLowerCase()
        .trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DiccionarioBottomSheet(
        palabra: palabraLimpia,
        backgroundColor: _backgroundColor,
        textColor: _textColor,
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

  // Menú inferior avanzado (Con soporte 100% para Modo Oscuro)
  void _mostrarAjustesAvanzados() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Para permitir que sea más alto
      backgroundColor: Colors.transparent, // Usamos Container interno
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final primaryColor = Theme.of(context).primaryColor;

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24.0),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Text(
                        'Ajustes de Lectura',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // --- TEMPORIZADOR ---
                      _buildSectionTitle(
                        'Temporizador de Lectura (Minutos)',
                        primaryColor,
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [0, 15, 30, 45, 60, 120].map((min) {
                            final isSelected = _timerMinutes == min;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(min == 0 ? 'Apagado' : '$min'),
                                selected: isSelected,
                                selectedColor: primaryColor,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Theme.of(context).cardColor
                                      : primaryColor,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).scaffoldBackgroundColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (val) {
                                  setModalState(() {});
                                  _iniciarTemporizador(min);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // --- ORIENTACIÓN ---
                      _buildSectionTitle(
                        'Orientación de Lectura',
                        primaryColor,
                      ),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children:
                            [
                              'Vertical (Arriba/Abajo)',
                              'Horizontal (Izq/Der)',
                              'Dos Páginas',
                              'Manga (Der/Izq)',
                            ].map((modo) {
                              return ChoiceChip(
                                label: Text(modo),
                                selected: _modoVista == modo,
                                selectedColor: primaryColor,
                                labelStyle: TextStyle(
                                  color: _modoVista == modo
                                      ? Theme.of(context).cardColor
                                      : primaryColor,
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).scaffoldBackgroundColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (sel) {
                                  setModalState(() => _modoVista = modo);
                                  setState(() => _modoVista = modo);
                                },
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 28),
                      // --- HERRAMIENTAS (MARCATEXTOS, DIBUJO, NOTAS) ---
                      _buildSectionTitle(
                        'Herramientas de Anotación',
                        primaryColor,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _ToolButton(
                                  icon: Icons.border_color_outlined,
                                  label: 'Resaltar',
                                  isActive:
                                      _highlightColor != Colors.transparent &&
                                      !_drawMode &&
                                      !_noteMode,
                                  onTap: () {
                                    setModalState(() {
                                      _drawMode = false;
                                      _noteMode = false;
                                      if (_highlightColor ==
                                          Colors.transparent) {
                                        _highlightColor = Colors.yellow;
                                      } else {
                                        _highlightColor = Colors
                                            .transparent; // Permite apagar el resaltador
                                      }
                                    });
                                    setState(() {});
                                  },
                                ),
                                _ToolButton(
                                  icon: Icons.draw_outlined,
                                  label: 'Dibujar',
                                  isActive: _drawMode,
                                  onTap: () {
                                    setModalState(() {
                                      _drawMode = !_drawMode;
                                      if (_drawMode) {
                                        _noteMode = false;
                                        _highlightColor = Colors.transparent;
                                      }
                                    });
                                    setState(() {});
                                  },
                                ),
                                _ToolButton(
                                  icon: Icons.sticky_note_2_outlined,
                                  label: 'Post-it',
                                  isActive: _noteMode,
                                  onTap: () {
                                    setModalState(() {
                                      _noteMode = !_noteMode;
                                      if (_noteMode) {
                                        _drawMode = false;
                                        _highlightColor = Colors.transparent;
                                      }
                                    });
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                            if (_highlightColor != Colors.transparent &&
                                !_drawMode &&
                                !_noteMode) ...[
                              Divider(
                                height: 32,
                                color: Theme.of(context).dividerColor,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children:
                                    [
                                      Colors.yellow,
                                      Colors.greenAccent,
                                      Colors.lightBlueAccent,
                                      Colors.pinkAccent,
                                      Colors.purpleAccent,
                                    ].map((color) {
                                      return GestureDetector(
                                        onTap: () {
                                          setModalState(
                                            () => _highlightColor = color,
                                          );
                                          setState(
                                            () => _highlightColor = color,
                                          );
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: _highlightColor == color
                                                  ? primaryColor
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // --- TIPOGRAFÍA Y TAMAÑO ---
                      _buildSectionTitle('Texto y Fuente', primaryColor),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.font_download_outlined,
                                  color: primaryColor,
                                  size: 22,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _fontFamily,
                                      dropdownColor: Theme.of(
                                        context,
                                      ).cardColor,
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 16,
                                      ),
                                      isExpanded: true,
                                      items:
                                          [
                                                'System',
                                                'Serif',
                                                'Sans Serif',
                                                'Monospace',
                                                'Dyslexic',
                                              ]
                                              .map(
                                                (f) => DropdownMenuItem(
                                                  value: f,
                                                  child: Text(f),
                                                ),
                                              )
                                              .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setModalState(
                                            () => _fontFamily = val,
                                          );
                                          setState(() => _fontFamily = val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Divider(
                              height: 24,
                              color: Theme.of(context).dividerColor,
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.text_fields,
                                  color: primaryColor,
                                  size: 22,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Slider(
                                    value: _fontSize,
                                    min: 12,
                                    max: 32,
                                    activeColor: primaryColor,
                                    inactiveColor: primaryColor.withOpacity(
                                      0.2,
                                    ),
                                    onChanged: (val) {
                                      setModalState(() => _fontSize = val);
                                      setState(() => _fontSize = val);
                                    },
                                  ),
                                ),
                                Text(
                                  '${_fontSize.toInt()}',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // --- PANTALLA Y BRILLO ---
                      _buildSectionTitle('Pantalla', primaryColor),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.brightness_low_outlined,
                                  color: primaryColor,
                                ),
                                Expanded(
                                  child: Slider(
                                    value: _brillo,
                                    activeColor: primaryColor,
                                    inactiveColor: primaryColor.withOpacity(
                                      0.2,
                                    ),
                                    onChanged: (val) {
                                      setModalState(() => _brillo = val);
                                      setState(() => _brillo = val);
                                      ScreenBrightness().setScreenBrightness(
                                        val,
                                      );
                                    },
                                  ),
                                ),
                                Icon(
                                  Icons.brightness_high_outlined,
                                  color: primaryColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Temas de Fondo',
                              style: TextStyle(
                                color: primaryColor.withOpacity(0.6),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _ColorThemeSelector(
                                  color: const Color(0xFFFFFFFF),
                                  name: 'Blanco',
                                  isSelected:
                                      _backgroundColor ==
                                      const Color(0xFFFFFFFF),
                                  onTap: () {
                                    setModalState(() {});
                                    _cambiarTema('Blanco');
                                  },
                                ),
                                _ColorThemeSelector(
                                  color: const Color(0xFFFBF0D9),
                                  name: 'Sepia',
                                  isSelected:
                                      _backgroundColor ==
                                      const Color(0xFFFBF0D9),
                                  onTap: () {
                                    setModalState(() {});
                                    _cambiarTema('Amarillo');
                                  },
                                ),
                                _ColorThemeSelector(
                                  color: const Color(0xFF000000),
                                  name: 'Noche',
                                  isSelected:
                                      _backgroundColor ==
                                      const Color(0xFF000000),
                                  onTap: () {
                                    setModalState(() {});
                                    _cambiarTema('Negro');
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color.withOpacity(0.5),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: _backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: IgnorePointer(
          ignoring: !_showUI,
          child: AnimatedOpacity(
            opacity: _showUI ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: AppBar(
              backgroundColor: _backgroundColor.withOpacity(0.9),
              elevation: 0,
              iconTheme: IconThemeData(color: _textColor),
              actions: [
                // Indicador Visual del Pomodoro
                if (_isPomodoroActive)
                  Center(
                    child: Text(
                      '${(_pomodoroSeconds ~/ 60).toString().padLeft(2, '0')}:${(_pomodoroSeconds % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: _isPomodoroBreak
                            ? Colors.green
                            : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    _isPomodoroActive ? Icons.timer : Icons.timer_outlined,
                    color: _isPomodoroActive
                        ? (_isPomodoroBreak ? Colors.green : Colors.redAccent)
                        : _textColor,
                  ),
                  tooltip: 'Modo Enfoque (Pomodoro)',
                  onPressed: _togglePomodoro,
                ),
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
                  onPressed:
                      _mostrarCitasFavoritas, // Abre el menú de favoritos
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () {
                    final textoCompartir = widget.documentPath != null
                        ? 'Estoy leyendo "${widget.titulo}" en OmniLibrary. ¡Échale un vistazo!'
                        : 'Lectura recomendada: "${widget.titulo}".\n\nOmniLibrary App';

                    Share.share(textoCompartir);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.tune), // Botón de ajustes avanzados
                  onPressed: _mostrarAjustesAvanzados,
                ),
              ],
            ),
          ),
        ),
      ),
      // Botón flotante para el Diccionario cuando se selecciona texto en un PDF
      floatingActionButton:
          _selectedPdfText != null && _selectedPdfText!.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                _mostrarDefinicion(_selectedPdfText!);
                setState(
                  () => _selectedPdfText = null,
                ); // Ocultar el botón después de buscar
              },
              icon: const Icon(Icons.language),
              label: const Text('Definir en Wikipedia'),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Theme.of(context).scaffoldBackgroundColor,
            )
          : null,
      // BARRA INFERIOR DE CONTROLES (Minimalista)
      // Ocultamos los controles si es un PDF, ya que manejan su propio flujo.
      bottomNavigationBar: widget.isPdf
          ? null
          : AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: !_showUI
                  ? const SizedBox.shrink()
                  : Container(
                      decoration: BoxDecoration(
                        color: _backgroundColor.withOpacity(0.9),
                        border: Border(
                          top: BorderSide(color: Colors.grey.withOpacity(0.2)),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: SafeArea(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.text_decrease,
                                    color: _textColor,
                                  ),
                                  onPressed: () => setState(
                                    () => _fontSize = (_fontSize > 14)
                                        ? _fontSize - 2
                                        : 14,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.text_increase,
                                    color: _textColor,
                                  ),
                                  onPressed: () => setState(
                                    () => _fontSize = (_fontSize < 30)
                                        ? _fontSize + 2
                                        : 30,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                _ColorButton(
                                  color: const Color(0xFFFFFFFF),
                                  onTap: () => _cambiarTema('Blanco'),
                                ),
                                const SizedBox(width: 12),
                                _ColorButton(
                                  color: const Color(0xFFFBF0D9),
                                  onTap: () => _cambiarTema('Amarillo'),
                                ),
                                const SizedBox(width: 12),
                                _ColorButton(
                                  color: const Color(0xFF000000),
                                  onTap: () => _cambiarTema('Negro'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
      // CUERPO DEL ARTÍCULO
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          setState(() => _showUI = !_showUI);
          HapticFeedback.lightImpact();
        },
        child: Stack(
          children: [
            // Capa Base: El Lector
            Positioned.fill(
              child: _cargandoProgreso
                  ? Center(child: CircularProgressIndicator(color: _textColor))
                  : widget.isPdf && widget.documentPath != null
                  ? _buildPdfViewer()
                  : widget.isEpub && widget.documentPath != null
                  ? _buildEpubViewer()
                  : _buildTextArticle(),
            ),
            // Capa Superior: La Isla Flotante del Pomodoro
            if (_isPomodoroActive)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(
                        0.85,
                      ), // Isla Dinámica estilo iOS
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: _isPomodoroBreak
                            ? Colors.green
                            : Colors.redAccent,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isPomodoroBreak ? Icons.coffee : Icons.psychology,
                          color: _isPomodoroBreak
                              ? Colors.green
                              : Colors.redAccent,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${(_pomodoroSeconds ~/ 60).toString().padLeft(2, '0')}:${(_pomodoroSeconds % 60).toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: _isPomodoroBreak
                                ? Colors.green
                                : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 1.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
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
              fontSize: 30, // H1 estilo Notion
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
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
              height: 1.7, // Interlineado premium (Obsidian style)
              letterSpacing: 0.2, // Espaciado súper nítido
              color: _textColor.withOpacity(0.85),
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

                  // Insertamos nuestro botón de "Resumir con IA"
                  buttonItems.insert(
                    2,
                    ContextMenuButtonItem(
                      label: '✨ Resumir con IA',
                      onPressed: () async {
                        final textEditingValue =
                            editableTextState.textEditingValue;
                        final selectedText = textEditingValue.selection
                            .textInside(textEditingValue.text)
                            .trim();

                        ContextMenuController.removeAny();

                        // Mostramos diálogo de carga
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => AlertDialog(
                            backgroundColor: _backgroundColor,
                            content: Row(
                              children: [
                                CircularProgressIndicator(
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Consultando a la IA...',
                                    style: TextStyle(color: _textColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );

                        final aiService = AiTranslationService();
                        final resumen = await aiService.getResumen(
                          widget.titulo,
                          selectedText,
                        );

                        if (context.mounted) {
                          Navigator.pop(
                            context,
                          ); // Cerramos el indicador de carga
                          // Mostramos el resumen
                          _mostrarDefinicion(
                            resumen,
                          ); // Reutilizamos tu método de diálogo, o creas uno nuevo
                        }
                      },
                    ),
                  );

                  // Insertamos nuestro botón de "Resaltar" y "Notas"
                  buttonItems.insert(
                    3,
                    ContextMenuButtonItem(
                      label: '🖍️ Resaltar',
                      onPressed: () {
                        ContextMenuController.removeAny();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Texto resaltado.',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            backgroundColor: Theme.of(context).cardColor,
                          ),
                        );
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

    if (_modoVista == 'Horizontal (Izq/Der)' ||
        _modoVista == 'Dos Páginas' ||
        _modoVista == 'Manga (Der/Izq)') {
      scrollDirection = PdfScrollDirection.horizontal;
      pageLayoutMode = PdfPageLayoutMode.single;
    }

    // Verificamos si es un PDF online (para la simulación) o un archivo descargado localmente
    final Widget viewer = widget.documentPath!.startsWith('http')
        ? SfPdfViewer.network(
            widget.documentPath!,
            key: _pdfViewerKey,
            controller: _pdfViewerController,
            scrollDirection: scrollDirection,
            pageLayoutMode: pageLayoutMode,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              if (_paginaGuardadaPdf > 1) {
                _pdfViewerController.jumpToPage(_paginaGuardadaPdf);
              }
            },
            onPageChanged: (PdfPageChangedDetails details) {
              LocalDbService.guardarProgreso(
                'pdf_page_${widget.documentPath}',
                details.newPageNumber,
              );
            },
            onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
              setState(() {
                _selectedPdfText = details.selectedText;
              });
            },
          )
        : SfPdfViewer.file(
            File(widget.documentPath!),
            key: _pdfViewerKey,
            controller: _pdfViewerController,
            scrollDirection: scrollDirection,
            pageLayoutMode: pageLayoutMode,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              if (_paginaGuardadaPdf > 1) {
                _pdfViewerController.jumpToPage(_paginaGuardadaPdf);
              }
            },
            onPageChanged: (PdfPageChangedDetails details) {
              LocalDbService.guardarProgreso(
                'pdf_page_${widget.documentPath}',
                details.newPageNumber,
              );
            },
            onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
              setState(() {
                _selectedPdfText = details.selectedText;
              });
            },
          );

    final bool modoAnotacionActivo =
        _drawMode || (_highlightColor != Colors.transparent && !_noteMode);

    final textDirection = _modoVista == 'Manga (Der/Izq)'
        ? TextDirection.rtl
        : TextDirection.ltr;

    return Stack(
      children: [
        Directionality(textDirection: textDirection, child: viewer),
        // Capa de dibujo que intercepta los toques solo si las herramientas están activas
        if (modoAnotacionActivo)
          Positioned.fill(
            child: GestureDetector(
              onPanStart: (details) {
                _trazoActual = _Trazo(
                  puntos: [details.localPosition],
                  color: _drawMode
                      ? Theme.of(context).primaryColor
                      : _highlightColor,
                  esResaltador: !_drawMode,
                );
                _trazos.add(_trazoActual!);
                _trazosUpdater.value++; // Notifica solo a la capa de pintura
              },
              onPanUpdate: (details) {
                if (_trazoActual != null) {
                  _trazoActual!.puntos.add(details.localPosition);
                  _trazosUpdater
                      .value++; // Dibuja fluido a 60/120fps sin bloquear la UI
                }
              },
              onPanEnd: (details) {
                _trazoActual = null;
              },
              child: RepaintBoundary(
                // Aísla la pintura del PDF subyacente
                child: ValueListenableBuilder<int>(
                  valueListenable: _trazosUpdater,
                  builder: (context, _, __) {
                    return CustomPaint(
                      painter: _AnotacionPainter(_trazos),
                      size: Size.infinite,
                    );
                  },
                ),
              ),
            ),
          ),
      ],
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

    // 1. Verificamos si hay alguna herramienta de dibujo/resaltado activa
    final bool modoAnotacionActivo =
        _drawMode || (_highlightColor != Colors.transparent && !_noteMode);

    // 2. Inyectamos los temas, colores y tipografía al visor de ePub
    final Widget epubWidget = Container(
      color: _backgroundColor,
      padding: const EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: 10.0,
      ), // Formato y márgenes de libro
      child: DefaultTextStyle(
        style: TextStyle(
          color: _textColor.withOpacity(0.85),
          fontSize: _fontSize,
          fontFamily: _fontFamily == 'System' ? null : _fontFamily,
          height: 1.7, // Interlineado premium tipo libro
          letterSpacing: 0.2,
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            textTheme: TextTheme(
              bodyMedium: TextStyle(
                color: _textColor.withOpacity(0.85),
                fontSize: _fontSize,
                fontFamily: _fontFamily == 'System' ? null : _fontFamily,
                height: 1.7,
              ),
            ),
          ),
          child: EpubView(controller: _epubController!),
        ),
      ),
    );

    // 3. Renderizamos el ePub con la misma capa de interactividad del PDF
    return Stack(
      children: [
        epubWidget,
        // ¡Habilitamos la capa de dibujo y resaltado también para ePubs!
        if (modoAnotacionActivo)
          Positioned.fill(
            child: GestureDetector(
              onPanStart: (details) {
                _trazoActual = _Trazo(
                  puntos: [details.localPosition],
                  color: _drawMode
                      ? Theme.of(context).primaryColor
                      : _highlightColor,
                  esResaltador: !_drawMode,
                );
                _trazos.add(_trazoActual!);
                _trazosUpdater.value++;
              },
              onPanUpdate: (details) {
                if (_trazoActual != null) {
                  _trazoActual!.puntos.add(details.localPosition);
                  _trazosUpdater.value++; // Dibuja fluido a 60/120fps
                }
              },
              onPanEnd: (details) {
                _trazoActual = null;
              },
              child: RepaintBoundary(
                child: ValueListenableBuilder<int>(
                  valueListenable: _trazosUpdater,
                  builder: (context, _, __) {
                    return CustomPaint(
                      painter: _AnotacionPainter(_trazos),
                      size: Size.infinite,
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// --- BOTTOM SHEET DEL DICCIONARIO WIKIPEDIA ---
class _DiccionarioBottomSheet extends StatefulWidget {
  final String palabra;
  final Color backgroundColor;
  final Color textColor;

  const _DiccionarioBottomSheet({
    required this.palabra,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  State<_DiccionarioBottomSheet> createState() =>
      _DiccionarioBottomSheetState();
}

class _DiccionarioBottomSheetState extends State<_DiccionarioBottomSheet> {
  bool _isLoading = true;
  String _definicion = '';
  String _tituloWiki = '';

  @override
  void initState() {
    super.initState();
    _buscarWiki();
  }

  Future<void> _buscarWiki() async {
    try {
      final resultados = await WikipediaService.buscarArticulos(widget.palabra);
      if (resultados.isNotEmpty) {
        _definicion = resultados[0]['snippet'] ?? 'Sin descripción.';
        _tituloWiki = resultados[0]['title'] ?? widget.palabra;
      } else {
        _definicion =
            'No se encontró una definición en Wikipedia para "${widget.palabra}".';
        _tituloWiki = widget.palabra;
      }
    } catch (e) {
      _definicion = 'Error al consultar Wikipedia.';
      _tituloWiki = widget.palabra;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: widget.backgroundColor.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
                  ),
                )
              else ...[
                Row(
                  children: [
                    Icon(
                      Icons.language,
                      color: widget.textColor.withOpacity(0.5),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _tituloWiki,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: widget.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _definicion,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: widget.textColor.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
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

// --- CLASES AUXILIARES PARA EL SISTEMA DE DIBUJO ---
class _Trazo {
  final List<Offset> puntos;
  final Color color;
  final bool esResaltador;

  _Trazo({
    required this.puntos,
    required this.color,
    this.esResaltador = false,
  });
}

class _AnotacionPainter extends CustomPainter {
  final List<_Trazo> trazos;

  _AnotacionPainter(this.trazos);

  @override
  void paint(Canvas canvas, Size size) {
    for (final trazo in trazos) {
      final paint = Paint()
        ..color = trazo.esResaltador
            ? trazo.color.withOpacity(0.4)
            : trazo.color
        ..strokeCap = trazo.esResaltador ? StrokeCap.square : StrokeCap.round
        ..strokeWidth = trazo.esResaltador
            ? 22.0
            : 3.0 // Resaltador ancho, lápiz delgado
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < trazo.puntos.length - 1; i++) {
        canvas.drawLine(trazo.puntos[i], trazo.puntos[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- NUEVOS WIDGETS AUXILIARES PARA AJUSTES AVANZADOS ---
class _ColorThemeSelector extends StatelessWidget {
  final Color color;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorThemeSelector({
    required this.color,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.withOpacity(0.3),
                width: isSelected ? 3 : 1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive
                  ? primaryColor.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isActive ? primaryColor : primaryColor.withOpacity(0.5),
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? primaryColor : primaryColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
