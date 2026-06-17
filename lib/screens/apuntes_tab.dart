import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/local_db_service.dart';

// Función top-level para offload de procesamiento
List<Map<String, String>> _procesarNotasEnFondo(
  List<Map<String, String>> notasRaw,
) {
  notasRaw.sort((a, b) {
    final fechaA =
        DateTime.tryParse(a['fecha'] ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final fechaB =
        DateTime.tryParse(b['fecha'] ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return fechaB.compareTo(fechaA);
  });
  return notasRaw;
}

class SeccionApuntes extends StatefulWidget {
  const SeccionApuntes({super.key});

  @override
  State<SeccionApuntes> createState() => _SeccionApuntesState();
}

class _SeccionApuntesState extends State<SeccionApuntes> {
  List<Map<String, String>> _misApuntes = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarApuntes();
  }

  Future<void> _cargarApuntes() async {
    await Future.delayed(const Duration(milliseconds: 250));
    var notasRaw = LocalDbService.obtenerNotas();

    if (notasRaw.isEmpty) {
      notasRaw = [
        {
          'titulo': 'Idea para App 💡',
          'contenido':
              'Un Tinder para libros. Deslizas portadas y si hay match, te recomienda leerlo.',
          'color': '0xFFFFF59D',
          'fecha': DateTime.now().toIso8601String(),
        },
        {
          'titulo': 'Frase del día',
          'contenido':
              'La única forma de hacer un gran trabajo es amar lo que haces. - Steve Jobs',
          'color': '0xFFB39DDB',
          'fecha': DateTime.now().toIso8601String(),
        },
      ];
      LocalDbService.guardarNotas(notasRaw);
    }

    final notasSafe = notasRaw.map((e) => Map<String, String>.from(e)).toList();
    final procesado = await compute(_procesarNotasEnFondo, notasSafe);

    if (mounted) {
      setState(() {
        _misApuntes = procesado;
        _isLoading = false;
      });
    }
  }

  String _formatearFecha(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate);
      final meses = [
        'Ene',
        'Feb',
        'Mar',
        'Abr',
        'May',
        'Jun',
        'Jul',
        'Ago',
        'Sep',
        'Oct',
        'Nov',
        'Dic',
      ];
      return '${date.day} ${meses[date.month - 1]}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  void _mostrarCreadorDeApuntes(
    BuildContext context, {
    Map<String, String>? apunteExistente,
    int? index,
  }) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            _EditorApuntePantalla(
              apunteExistente: apunteExistente,
              index: index,
              onSave: (titulo, contenido, color, forma) {
                setState(() {
                  if (apunteExistente != null && index != null) {
                    _misApuntes[index] = {
                      'titulo': titulo,
                      'contenido': contenido,
                      'color': color,
                      'forma': forma,
                      'fecha':
                          apunteExistente['fecha'] ??
                          DateTime.now().toIso8601String(),
                    };
                  } else {
                    _misApuntes.insert(0, {
                      'titulo': titulo,
                      'contenido': contenido,
                      'color': color,
                      'forma': forma,
                      'fecha': DateTime.now().toIso8601String(),
                    });
                  }
                });
                LocalDbService.guardarNotas(_misApuntes);
              },
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Mis Notas',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.2,
          ),
        ),
        toolbarHeight: 100,
        centerTitle: false,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            _mostrarCreadorDeApuntes(context);
          },
          shape: const CircleBorder(),
          elevation: 4,
          backgroundColor: Colors.amber.shade500,
          foregroundColor: Colors.white,
          child: const Icon(Icons.edit_square),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
                strokeWidth: 2,
              ).animate().fade(duration: 400.ms),
            )
          : _construirMuroDeNotas(isDark),
    );
  }

  IconData _obtenerIconoForma(String? forma) {
    switch (forma) {
      case 'circulo':
        return Icons.circle;
      case 'triangulo':
        return Icons.change_history;
      case 'rombo':
        return Icons.diamond;
      case 'corazon':
        return Icons.favorite;
      case 'estrella':
        return Icons.star;
      case 'manzana':
        return Icons.apple;
      case 'cuadrado':
      default:
        return Icons.crop_square;
    }
  }

  Widget _construirMuroDeNotas(bool isDark) {
    final apuntesFiltrados = _searchQuery.isEmpty
        ? _misApuntes
        : _misApuntes
              .where(
                (n) =>
                    (n['titulo'] ?? '').toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    (n['contenido'] ?? '').toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey.shade800.withOpacity(0.6)
                        : Colors.grey.shade300.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search, color: Colors.grey, size: 20),
                      hintText: 'Buscar nota...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: apuntesFiltrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_note,
                          size: 80,
                          color: Colors.blueGrey.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tu cuaderno está en blanco.',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                    itemCount: apuntesFiltrados.length,
                    itemBuilder: (context, index) {
                      final apunte = apuntesFiltrados[index];
                      final realIndex = _misApuntes.indexOf(apunte);
                      final esTarea = apunte['tipo'] == 'tarea';
                      final isCompletada = apunte['completada'] == 'true';
                      final colorHex = apunte['color'] ?? '0xFFFFF59D';
                      final noteColor = Color(int.parse(colorHex));

                      return GestureDetector(
                        onTap: () {
                          if (esTarea) {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _misApuntes[realIndex]['completada'] =
                                  isCompletada ? 'false' : 'true';
                            });
                            LocalDbService.guardarNotas(_misApuntes);
                          } else {
                            _mostrarCreadorDeApuntes(
                              context,
                              apunteExistente: apunte,
                              index: realIndex,
                            );
                          }
                        },
                        onLongPress: () {
                          HapticFeedback.mediumImpact();
                          _mostrarMenuContextualNota(realIndex);
                        },
                        child: Hero(
                          tag: 'apunte_$realIndex',
                          child: Material(
                            color: Colors.transparent,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: isCompletada ? 0.5 : 1.0,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: noteColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (esTarea) ...[
                                          Icon(
                                            isCompletada
                                                ? Icons.check_circle
                                                : Icons.radio_button_unchecked,
                                            size: 18,
                                            color: isCompletada
                                                ? Colors.green
                                                : Colors.black87,
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Expanded(
                                          child: Text(
                                            apunte['titulo']?.isNotEmpty == true
                                                ? apunte['titulo']!
                                                : 'Nueva nota',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black87,
                                              decoration: isCompletada
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      apunte.containsKey('fecha')
                                          ? _formatearFecha(apunte['fecha'])
                                          : '',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (!esTarea)
                                      Expanded(
                                        child: Text(
                                          apunte['contenido']?.isNotEmpty ==
                                                  true
                                              ? apunte['contenido']!
                                              : 'No hay texto adicional',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            height: 1.4,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 4,
                                          overflow: TextOverflow.fade,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _mostrarMenuContextualNota(int index) {
    final apunte = _misApuntes[index];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              color: isDark
                  ? Colors.grey.shade900.withOpacity(0.8)
                  : Colors.white.withOpacity(0.8),
              padding: const EdgeInsets.only(bottom: 32, top: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Icon(
                      Icons.edit_outlined,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text(
                      'Editar apunte',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _mostrarCreadorDeApuntes(
                        context,
                        apunteExistente: apunte,
                        index: index,
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.color_lens_outlined,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text(
                      'Cambiar color',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _cambiarColorRapido(index);
                    },
                  ),
                  Divider(color: Colors.grey.withOpacity(0.2)),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    title: const Text(
                      'Eliminar',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                      setState(() {
                        _misApuntes.removeAt(index);
                      });
                      LocalDbService.guardarNotas(_misApuntes);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _cambiarColorRapido(int index) {
    final colores = [
      '0xFFFFF59D',
      '0xFFB39DDB',
      '0xFFA5D6A7',
      '0xFF90CAF9',
      '0xFFFFAB91',
    ];
    final currentColor = _misApuntes[index]['color'] ?? '0xFFFFF59D';
    int nextIdx = (colores.indexOf(currentColor) + 1) % colores.length;
    setState(() {
      _misApuntes[index]['color'] = colores[nextIdx];
    });
    LocalDbService.guardarNotas(_misApuntes);
  }
}

class _EditorApuntePantalla extends StatefulWidget {
  final Map<String, String>? apunteExistente;
  final int? index;
  final Function(String, String, String, String) onSave;

  const _EditorApuntePantalla({
    this.apunteExistente,
    this.index,
    required this.onSave,
  });

  @override
  State<_EditorApuntePantalla> createState() => _EditorApuntePantallaState();
}

class _EditorApuntePantallaState extends State<_EditorApuntePantalla> {
  late TextEditingController _tituloController;
  late TextEditingController _contenidoController;
  late String _selectedColor;
  late String _selectedForma;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(
      text: widget.apunteExistente?['titulo'] ?? '',
    );
    _contenidoController = TextEditingController(
      text: widget.apunteExistente?['contenido'] ?? '',
    );
    _selectedColor = widget.apunteExistente?['color'] ?? '0xFF90CAF9';
    _selectedForma = widget.apunteExistente?['forma'] ?? 'cuadrado';
  }

  void _insertFormat(String prefix, String suffix) {
    final text = _contenidoController.text;
    final selection = _contenidoController.selection;
    if (selection.start >= 0 && selection.end >= 0) {
      final selectedText = selection.textInside(text);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selectedText$suffix',
      );
      _contenidoController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + prefix.length + selectedText.length,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _contenidoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.4),
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 300)
            Navigator.pop(context);
        },
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
        child: Center(
          child: Hero(
            tag: 'apunte_${widget.index ?? "nuevo"}',
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.95,
                  height: MediaQuery.of(context).size.height * 0.85,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Color(int.parse(_selectedColor)),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(_selectedColor),
                          ).withOpacity(0.15),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(22),
                          ),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.format_bold),
                                onPressed: () => _insertFormat('**', '**'),
                                tooltip: 'Negrita',
                              ),
                              IconButton(
                                icon: const Icon(Icons.format_italic),
                                onPressed: () => _insertFormat('_', '_'),
                                tooltip: 'Cursiva',
                              ),
                              IconButton(
                                icon: const Icon(Icons.check_box_outline_blank),
                                onPressed: () => _insertFormat('- [ ] ', ''),
                                tooltip: 'Casilla',
                              ),
                              IconButton(
                                icon: const Icon(Icons.save),
                                onPressed: () {
                                  widget.onSave(
                                    _tituloController.text,
                                    _contenidoController.text,
                                    _selectedColor,
                                    _selectedForma,
                                  );
                                  Navigator.pop(context);
                                },
                                tooltip: 'Guardar',
                              ),
                              Container(
                                height: 24,
                                width: 1,
                                color: Colors.grey,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              ...[
                                    '0xFFFFF59D',
                                    '0xFFB39DDB',
                                    '0xFFA5D6A7',
                                    '0xFF90CAF9',
                                    '0xFFFFAB91',
                                  ]
                                  .map(
                                    (c) => GestureDetector(
                                      onTap: () =>
                                          setState(() => _selectedColor = c),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Color(int.parse(c)),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _selectedColor == c
                                                ? Theme.of(context).primaryColor
                                                : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              TextField(
                                controller: _tituloController,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).primaryColor,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Título del documento...',
                                  border: InputBorder.none,
                                ),
                                textCapitalization:
                                    TextCapitalization.sentences,
                              ),
                              Divider(color: Theme.of(context).dividerColor),
                              Expanded(
                                child: TextField(
                                  controller: _contenidoController,
                                  maxLines: null,
                                  expands: true,
                                  style: TextStyle(
                                    fontSize: 17,
                                    height: 1.6,
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.9),
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Comienza a escribir tu apunte...',
                                    border: InputBorder.none,
                                  ),
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
