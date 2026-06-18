import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/local_db_service.dart';

Map<String, dynamic> _procesarNotasEnFondo(Map<String, dynamic> data) {
  final notas = List<Map<String, String>>.from(data['notas'] ?? []);
  final tareas = List<Map<String, dynamic>>.from(data['tareas'] ?? []);

  notas.sort((a, b) {
    final fechaA = DateTime.tryParse(a['fecha'] ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final fechaB = DateTime.tryParse(b['fecha'] ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return fechaB.compareTo(fechaA);
  });
  return {'notas': notas, 'tareas': tareas};
}

class ApuntesTab extends StatefulWidget {
  const ApuntesTab({super.key});
  @override
  State<ApuntesTab> createState() => _ApuntesTabState();
}

class _ApuntesTabState extends State<ApuntesTab> {
  List<Map<String, String>> _misApuntes = [];
  String _searchQuery = '';
  int _modoVistaApuntes = 0;
  List<Map<String, dynamic>> _misTareas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarApuntes();
  }

  Future<void> _cargarApuntes() async {
    await Future.delayed(const Duration(milliseconds: 250));
    var notasRaw = LocalDbService.obtenerNotas();
    var tareasRaw = LocalDbService.obtenerTareas();

    if (notasRaw.isEmpty) {
      notasRaw = [
        {
          'titulo': 'Idea para App 💡',
          'contenido':
              'Un Tinder para libros. Deslizas portadas y si hay match, te recomienda leerlo.',
          'color': '0xFFFFF59D',
          'forma': 'cuadrado',
          'fecha': DateTime.now().toIso8601String(),
        },
      ];
      LocalDbService.guardarNotas(notasRaw);
    }

    final notasSafe = notasRaw.map((e) => Map<String, String>.from(e)).toList();
    final tareasSafe =
        tareasRaw.map((e) => Map<String, dynamic>.from(e)).toList();

    final procesado = await compute(_procesarNotasEnFondo, <String, dynamic>{
      'notas': notasSafe,
      'tareas': tareasSafe,
    });

    if (mounted) {
      setState(() {
        _misApuntes = List<Map<String, String>>.from(procesado['notas']);
        _misTareas = List<Map<String, dynamic>>.from(procesado['tareas']);
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
              final apunteData = {
                'titulo': titulo,
                'contenido': contenido,
                'color': color,
                'forma': forma,
                'fecha': apunteExistente?['fecha'] ??
                    DateTime.now().toIso8601String(),
              };
              if (apunteExistente != null && index != null) {
                _misApuntes[index] = apunteData;
              } else {
                _misApuntes.insert(0, apunteData);
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

  void _mostrarCreadorDeTareas(BuildContext context) {
    final tareaController = TextEditingController();
    String fechaSel = 'Próximamente';
    bool esPrioridad = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              color: isDark
                  ? Colors.grey[900]!.withOpacity(0.85)
                  : Colors.white.withOpacity(0.85),
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SafeArea(
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics()),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(16)),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: tareaController,
                                      autofocus: true,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      decoration: const InputDecoration(
                                          hintText: '¿Qué necesitas recordar?',
                                          border: InputBorder.none),
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500),
                                      onChanged: (value) =>
                                          setModalState(() {}),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        CupertinoIcons.arrow_up_circle_fill,
                                        size: 30),
                                    color: Theme.of(context).primaryColor,
                                    disabledColor: Colors.grey,
                                    onPressed: tareaController.text
                                            .trim()
                                            .isEmpty
                                        ? null
                                        : () {
                                            HapticFeedback.lightImpact();
                                            setState(() {
                                              _misTareas.insert(0, {
                                                'titulo':
                                                    tareaController.text.trim(),
                                                'completada': false,
                                                'fecha': fechaSel,
                                                'prioridad':
                                                    esPrioridad.toString()
                                              });
                                            });
                                            LocalDbService.guardarTareas(
                                                _misTareas);
                                            Navigator.pop(context);
                                          },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    setModalState(() => fechaSel =
                                        fechaSel == 'Próximamente'
                                            ? 'Hoy'
                                            : 'Próximamente');
                                  },
                                  icon: Icon(CupertinoIcons.calendar,
                                      color: fechaSel == 'Hoy'
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey),
                                ),
                                IconButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    setModalState(
                                        () => esPrioridad = !esPrioridad);
                                  },
                                  icon: Icon(
                                      esPrioridad
                                          ? CupertinoIcons.flag_fill
                                          : CupertinoIcons.flag,
                                      color: esPrioridad
                                          ? CupertinoColors.systemOrange
                                          : Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
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
                      CupertinoIcons.pencil,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text(
                      'Editar apunte',
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500),
                    ),
                    onTap: () {
                      HapticFeedback.lightImpact();
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
                      CupertinoIcons.share,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text(
                      'Exportar como Texto',
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500),
                    ),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      final texto =
                          '${apunte['titulo'] ?? 'Sin título'}\n\n${apunte['contenido'] ?? ''}';
                      Share.share(texto, subject: apunte['titulo']);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      CupertinoIcons.paintbrush,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text(
                      'Cambiar color',
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500),
                    ),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      _cambiarColorRapido(index);
                    },
                  ),
                  Divider(color: Colors.grey.withOpacity(0.2)),
                  ListTile(
                    leading: const Icon(
                      CupertinoIcons.delete,
                      color: CupertinoColors.destructiveRed,
                    ),
                    title: const Text(
                      'Eliminar',
                      style: TextStyle(
                          color: CupertinoColors.destructiveRed,
                          fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                      _confirmarEliminar(index);
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

  void _confirmarEliminar(int index) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(
          'Eliminar apunte',
        ),
        content: Text(
          '¿Deseas eliminar este apunte?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx);
              setState(() => _misApuntes.removeAt(index));
              LocalDbService.guardarNotas(_misApuntes);
            },
            child: const Text(
              'Sí',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
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
                      hintText: 'Buscar',
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
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
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
                      final noteColor = Color(
                        int.parse(apunte['color'] ?? '0xFFFFF59D'),
                      );

                      return GestureDetector(
                        onTap: () {
                          _mostrarCreadorDeApuntes(
                            context,
                            apunteExistente: apunte,
                            index: realIndex,
                          );
                        },
                        onLongPress: () {
                          HapticFeedback.mediumImpact();
                          _mostrarMenuContextualNota(realIndex);
                        },
                        child: Hero(
                          tag: 'apunte_$realIndex',
                          child: Material(
                            color: Colors.transparent,
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
                              child: Stack(
                                children: [
                                  Positioned(
                                    right: -25,
                                    bottom: -25,
                                    child: Icon(
                                      _obtenerIconoForma(apunte['forma']),
                                      size: 110,
                                      color: Colors.black.withOpacity(0.04),
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        apunte['titulo']?.isNotEmpty == true
                                            ? apunte['titulo']!
                                            : 'Nueva nota',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                                      Expanded(
                                        child: Text(
                                          apunte['contenido']?.isNotEmpty ==
                                                  true
                                              ? apunte['contenido']!
                                              : 'No hay texto',
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
                                ],
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

  Widget _construirLibretaTareas(bool isDark) {
    final tareasFiltradas = _searchQuery.isEmpty
        ? _misTareas
        : _misTareas
            .where(
              (t) => (t['titulo'] ?? '').toLowerCase().contains(
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
                      hintText: 'Buscar tarea...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: tareasFiltradas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fact_check_outlined,
                          size: 80,
                          color: Colors.blueGrey.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tu libreta está vacía.',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(0, 20, 0, 140),
                    itemCount: tareasFiltradas.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      indent: 64,
                      color: Theme.of(context).dividerColor.withOpacity(0.2),
                      thickness: 0.5,
                    ),
                    itemBuilder: (context, index) {
                      final tarea = tareasFiltradas[index];
                      final realIndex = _misTareas.indexOf(tarea);
                      final bool isCompletada = tarea['completada'] == true;
                      final isPrioridad = tarea['prioridad'] == 'true';
                      final fecha = tarea['fecha'] ?? 'Próximamente';

                      return Dismissible(
                        key: Key('tarea_${realIndex}_${tarea['titulo']}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          color: Colors.redAccent,
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        onDismissed: (direction) {
                          HapticFeedback.mediumImpact();
                          setState(() {
                            _misTareas.removeAt(realIndex);
                          });
                          LocalDbService.guardarTareas(_misTareas);
                        },
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _misTareas[realIndex]['completada'] =
                                  !isCompletada;
                            });
                            LocalDbService.guardarTareas(_misTareas);
                          },
                          leading: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutCubic,
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isCompletada
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.shade400,
                                width: 1.5,
                              ),
                              color: isCompletada
                                  ? Theme.of(context).primaryColor
                                  : Colors.transparent,
                            ),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: isCompletada ? 1.0 : 0.0,
                              child: const Icon(
                                Icons.check,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 17,
                                  color: isCompletada
                                      ? Colors.grey
                                      : Theme.of(context).primaryColor,
                                  decoration: isCompletada
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                                child: Text(tarea['titulo'] ?? 'Nueva tarea'),
                              ),
                              if (!isCompletada &&
                                  (fecha != 'Próximamente' || isPrioridad))
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      if (fecha != 'Próximamente')
                                        Text(
                                          fecha,
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      if (fecha != 'Próximamente' &&
                                          isPrioridad)
                                        const SizedBox(width: 8),
                                      if (isPrioridad)
                                        const Icon(
                                          Icons.flag,
                                          color: Colors.orange,
                                          size: 14,
                                        ),
                                    ],
                                  ),
                                ),
                            ],
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
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
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 64),
                  title: Text(
                    _modoVistaApuntes == 0 ? 'Mis Notas' : 'Recordatorios',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.0,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Muro de Notas'),
                      selected: _modoVistaApuntes == 0,
                      onSelected: (val) {
                        HapticFeedback.lightImpact();
                        setState(() => _modoVistaApuntes = 0);
                      },
                    ),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: const Text('Libreta de Tareas'),
                      selected: _modoVistaApuntes == 1,
                      onSelected: (val) {
                        HapticFeedback.lightImpact();
                        setState(() => _modoVistaApuntes = 1);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                      strokeWidth: 2,
                    ).animate().fade(duration: 400.ms),
                  )
                : _modoVistaApuntes == 0
                    ? _construirMuroDeNotas(isDark)
                    : _construirLibretaTareas(isDark),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            if (_modoVistaApuntes == 0) {
              _mostrarCreadorDeApuntes(context);
            } else {
              _mostrarCreadorDeTareas(context);
            }
          },
          shape: const CircleBorder(),
          elevation: 4,
          backgroundColor: Colors.amber.shade500,
          foregroundColor: Colors.white,
          child: const Icon(Icons.edit_square),
        ),
      ),
    );
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
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300) {
            widget.onSave(
              _tituloController.text,
              _contenidoController.text,
              _selectedColor,
              'cuadrado',
            );
            Navigator.pop(context);
          }
        },
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onSave(
            _tituloController.text,
            _contenidoController.text,
            _selectedColor,
            'cuadrado',
          );
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
                              ),
                              IconButton(
                                icon: const Icon(Icons.format_list_bulleted),
                                onPressed: () => _insertFormat('- ', ''),
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
                                  hintText: 'Título...',
                                  hintStyle: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.3),
                                  ),
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
                                    hintText: 'Comienza a escribir...',
                                    hintStyle: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.4),
                                    ),
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
