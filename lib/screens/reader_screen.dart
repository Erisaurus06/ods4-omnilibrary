import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:epub_view/epub_view.dart';
import 'package:screen_brightness/screen_brightness.dart';

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

  // Función para cambiar el tema de lectura
  void _cambiarTema(String tema) {
    setState(() {
      if (tema == 'Claro') {
        _backgroundColor = const Color(0xFFFAFAFA);
        _textColor = Colors.black87;
      } else if (tema == 'Amarillo') {
        _backgroundColor = const Color(0xFFFFF9C4); // Amarillo suave lectura
        _textColor = Colors.black87;
      } else if (tema == 'Gris') {
        _backgroundColor = const Color(
          0xFFE0E0E0,
        ); // Gris claro elegante y neutral
        _textColor = Colors.black87; // Negro oscuro para máximo contraste
      } else if (tema == 'Oscuro') {
        _backgroundColor = const Color(0xFF121212); // Negro suave
        _textColor = Colors.white70; // Blanco tenue para no lastimar la vista
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
    // Inicializamos el controlador de ePub si aplica y el archivo existe
    if (widget.isEpub && widget.documentPath != null) {
      final file = File(widget.documentPath!);
      if (file.existsSync()) {
        _epubController = EpubController(document: EpubDocument.openFile(file));
      }
    }
    _initBrightness();
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
    _epubController?.dispose();
    super.dispose();
  }

  // Menú inferior avanzado
  void _mostrarAjustesAvanzados() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Control de Brillo (Simulado, requiere paquete screen_brightness para afectar hardware)
                    Row(
                      children: [
                        const Icon(Icons.brightness_low, color: Colors.grey),
                        Expanded(
                          child: Slider(
                            value: _brillo,
                            activeColor: Colors.black,
                            onChanged: (val) {
                              setModalState(() => _brillo = val);
                              setState(() => _brillo = val);
                              ScreenBrightness().setScreenBrightness(val);
                            },
                          ),
                        ),
                        const Icon(Icons.brightness_high, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Modos de Vista
                    const Text(
                      'Modo de Visualización',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            [
                              'Lineal',
                              'Libre',
                              'Manga',
                              'Dos Hojas',
                              'Desparramado',
                            ].map((modo) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(modo),
                                  selected: _modoVista == modo,
                                  selectedColor: Colors.black,
                                  labelStyle: TextStyle(
                                    color: _modoVista == modo
                                        ? Colors.white
                                        : Colors.black,
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
                    // Traducción IA Inteligente
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Traducción Inteligente IA',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Traduce contextos (libros, mangas) manteniendo el formato original.',
                      ),
                      activeColor: Colors.black,
                      value: _modoTraduccion,
                      onChanged: (val) {
                        setModalState(() => _modoTraduccion = val);
                        setState(() => _modoTraduccion = val);
                      },
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
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              // Lógica para guardar el artículo
            },
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
                          color: const Color(0xFFFAFAFA),
                          onTap: () => _cambiarTema('Claro'),
                        ),
                        const SizedBox(width: 12),
                        _ColorButton(
                          color: const Color(0xFFFFF9C4), // Botón Amarillo
                          onTap: () => _cambiarTema('Amarillo'),
                        ),
                        const SizedBox(width: 12),
                        _ColorButton(
                          color: const Color(
                            0xFFE0E0E0,
                          ), // Color gris en el botón
                          onTap: () => _cambiarTema('Gris'),
                        ),
                        const SizedBox(width: 12),
                        _ColorButton(
                          color: const Color(0xFF121212),
                          onTap: () => _cambiarTema('Oscuro'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      // CUERPO DEL ARTÍCULO
      body: widget.isPdf && widget.documentPath != null
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
          Text(
            widget.contenido ??
                'La educación es el arma más poderosa que puedes usar para cambiar el mundo.\n\nEl acceso a la información siempre ha sido un pilar fundamental para el desarrollo humano. Sin embargo, en la era digital, nos enfrentamos a un nuevo reto: la sobreinformación y la fragmentación del conocimiento.',
            style: TextStyle(
              fontSize: _fontSize,
              height: 1.6, // Interlineado amplio para lectura cómoda
              color: _textColor.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
    // Verificamos si es un PDF online (para la simulación) o un archivo descargado localmente
    if (widget.documentPath!.startsWith('http')) {
      return SfPdfViewer.network(widget.documentPath!);
    }
    return SfPdfViewer.file(File(widget.documentPath!));
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
