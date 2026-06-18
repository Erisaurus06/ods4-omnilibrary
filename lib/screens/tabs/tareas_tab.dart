import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/local_db_service.dart';

class SeccionTareas extends StatefulWidget {
  const SeccionTareas({super.key});

  @override
  State<SeccionTareas> createState() => _SeccionTareasState();
}

class _SeccionTareasState extends State<SeccionTareas> {
  List<Map<String, dynamic>> _misTareas = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarTareas();
  }

  Future<void> _cargarTareas() async {
    await Future.delayed(const Duration(milliseconds: 250));
    var tareasRaw = LocalDbService.obtenerTareas();
    final tareasSafe = tareasRaw.map((e) {
      final map = Map<String, dynamic>.from(e);
      // Aseguramos que cada tarea tenga un ID único para la jerarquía de ramas
      if (!map.containsKey('id'))
        map['id'] = DateTime.now().microsecondsSinceEpoch.toString() +
            map.hashCode.toString();
      return map;
    }).toList();

    if (mounted) {
      setState(() {
        _misTareas = tareasSafe;
        _isLoading = false;
      });
    }
  }

  void _mostrarCreadorDeTareas(BuildContext context) {
    final tareaController = TextEditingController();
    String fechaSel = 'Próximamente';
    bool esPrioridad = false;
    String? parentId; // ID de la rama padre

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: 25, sigmaY: 25), // Regla 1: Glassmorphism
                  child: Container(
                    color: isDark
                        ? Colors.black.withOpacity(0.75)
                        : Colors.white.withOpacity(0.75),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade900.withOpacity(0.5)
                                  : Colors.grey.shade200.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: tareaController,
                                    autofocus: true,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    maxLines: null,
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.3),
                                    decoration: InputDecoration(
                                      hintText: parentId != null
                                          ? 'Añadir subtarea...'
                                          : '¿Qué necesitas recordar?',
                                      hintStyle: TextStyle(
                                          color: Colors.grey.withOpacity(0.8)),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    onChanged: (value) => setModalState(() {}),
                                  ),
                                ),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: tareaController.text.trim().isEmpty
                                      ? null
                                      : () {
                                          HapticFeedback
                                              .mediumImpact(); // Regla 5: Haptics
                                          setState(() {
                                            _misTareas.insert(0, {
                                              'id': DateTime.now()
                                                  .microsecondsSinceEpoch
                                                  .toString(),
                                              'titulo':
                                                  tareaController.text.trim(),
                                              'completada': false,
                                              'fecha': fechaSel,
                                              'prioridad':
                                                  esPrioridad.toString(),
                                              'parentId': parentId,
                                            });
                                          });
                                          LocalDbService.guardarTareas(
                                              _misTareas);
                                          Navigator.pop(context);
                                        },
                                  child: const Icon(
                                      CupertinoIcons.arrow_up_circle_fill,
                                      size: 32,
                                      color: CupertinoColors.activeBlue),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              CupertinoButton(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  setModalState(() => fechaSel =
                                      fechaSel == 'Próximamente'
                                          ? 'Hoy'
                                          : 'Próximamente');
                                },
                                child: Icon(CupertinoIcons.calendar,
                                    color: fechaSel == 'Hoy'
                                        ? CupertinoColors.activeBlue
                                        : Colors.grey,
                                    size: 24),
                              ),
                              CupertinoButton(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  setModalState(
                                      () => esPrioridad = !esPrioridad);
                                },
                                child: Icon(
                                    esPrioridad
                                        ? CupertinoIcons.flag_fill
                                        : CupertinoIcons.flag,
                                    color: esPrioridad
                                        ? CupertinoColors.systemOrange
                                        : Colors.grey,
                                    size: 24),
                              ),
                              const Spacer(),
                              // Selector de Ramas (Parent Tarea)
                              CupertinoButton(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  final parents = _misTareas
                                      .where((t) => t['parentId'] == null)
                                      .toList();
                                  if (parents.isEmpty)
                                    return; // No hay ramas principales
                                  showCupertinoModalPopup(
                                    context: context,
                                    builder: (ctx) => CupertinoActionSheet(
                                      title: const Text(
                                          'Convertir en subtarea de...',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      actions: parents
                                          .map((p) =>
                                              CupertinoActionSheetAction(
                                                onPressed: () {
                                                  HapticFeedback
                                                      .selectionClick();
                                                  setModalState(
                                                      () => parentId = p['id']);
                                                  Navigator.pop(ctx);
                                                },
                                                child: Text(p['titulo'] ?? '',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                              ))
                                          .toList(),
                                      cancelButton: CupertinoActionSheetAction(
                                        isDestructiveAction: true,
                                        onPressed: () {
                                          setModalState(() => parentId = null);
                                          Navigator.pop(ctx);
                                        },
                                        child: const Text(
                                            'Ninguna (Rama principal)',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Icon(CupertinoIcons.arrow_turn_down_right,
                                        color: parentId != null
                                            ? CupertinoColors.activeBlue
                                            : Colors.grey,
                                        size: 20),
                                    if (parentId != null)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 6.0),
                                        child: Text('Subtarea',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color:
                                                    CupertinoColors.activeBlue,
                                                fontWeight: FontWeight.w600)),
                                      )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            _mostrarCreadorDeTareas(context);
          },
          shape: const CircleBorder(),
          elevation: 8,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
                strokeWidth: 2,
              ).animate().fade(duration: 400.ms),
            )
          : _construirLibretaTareas(isDark),
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
      child: CustomScrollView(
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
                    'Recordatorios',
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
                      color: isDark
                          ? Colors.grey.shade800.withOpacity(0.6)
                          : Colors.grey.shade300.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: const InputDecoration(
                        icon: Icon(CupertinoIcons.search,
                            color: CupertinoColors.systemGrey, size: 20),
                        hintText: 'Buscar tarea...',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (tareasFiltradas.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_rectangle,
                      size: 80,
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        'Tu libreta está vacía.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 140),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                    _construirNodosArbol(tareasFiltradas, isDark)),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _construirNodosArbol(
      List<Map<String, dynamic>> filtradas, bool isDark) {
    List<Widget> nodos = [];

    // Si hay búsqueda activa, aplanamos la lista (no mostramos ramas para no romper UX de búsqueda)
    if (_searchQuery.isNotEmpty) {
      return filtradas
          .map((t) =>
              _construirItemTarea(t, isSubtask: false, isLastChild: false))
          .toList();
    }

    final principales = filtradas.where((t) => t['parentId'] == null).toList();

    for (int i = 0; i < principales.length; i++) {
      final padre = principales[i];
      nodos.add(
          _construirItemTarea(padre, isSubtask: false, isLastChild: false));

      final subtareas =
          filtradas.where((t) => t['parentId'] == padre['id']).toList();
      for (int j = 0; j < subtareas.length; j++) {
        nodos.add(_construirItemTarea(subtareas[j],
            isSubtask: true, isLastChild: j == subtareas.length - 1));
      }
      if (i < principales.length - 1 && subtareas.isEmpty) {
        nodos.add(Divider(
            height: 1,
            indent: 64,
            color: Theme.of(context).dividerColor.withOpacity(0.2),
            thickness: 0.5));
      }
    }

    // Prevención: Mostrar tareas huérfanas que pudieron perder a su padre
    final huerfanas = filtradas
        .where((t) =>
            t['parentId'] != null &&
            !principales.any((p) => p['id'] == t['parentId']))
        .toList();
    for (var huerfana in huerfanas) {
      nodos.add(
          _construirItemTarea(huerfana, isSubtask: false, isLastChild: false));
    }

    return nodos;
  }

  Widget _construirItemTarea(Map<String, dynamic> tarea,
      {required bool isSubtask, required bool isLastChild}) {
    final realIndex = _misTareas.indexWhere((t) => t['id'] == tarea['id']);
    if (realIndex == -1) return const SizedBox.shrink();

    final bool isCompletada = tarea['completada'] == true;
    final isPrioridad = tarea['prioridad'] == 'true';
    final fecha = tarea['fecha'] ?? 'Próximamente';

    final Widget contenido = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact(); // Regla 5: Haptics
              setState(
                  () => _misTareas[realIndex]['completada'] = !isCompletada);
              LocalDbService.guardarTareas(_misTareas);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(top: 2),
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
                child: const Icon(CupertinoIcons.checkmark,
                    size: 16, color: Colors.white, weight: 800),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            // Blindaje contra Overflows
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 17,
                    letterSpacing: -0.3,
                    color: isCompletada
                        ? Colors.grey
                        : Theme.of(context).primaryColor,
                    decoration: isCompletada
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  child: Text(tarea['titulo'] ?? 'Sin título'),
                ),
                if (!isCompletada && (fecha != 'Próximamente' || isPrioridad))
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Row(
                      children: [
                        if (fecha != 'Próximamente')
                          Flexible(
                            child: Text(
                              fecha,
                              style: const TextStyle(
                                  color: CupertinoColors.destructiveRed,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (fecha != 'Próximamente' && isPrioridad)
                          const SizedBox(width: 8),
                        if (isPrioridad)
                          const Icon(CupertinoIcons.flag_fill,
                              color: CupertinoColors.systemOrange, size: 14),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    final dismissible = Dismissible(
      key: Key('tarea_${tarea['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: CupertinoColors.destructiveRed,
        child: const Icon(CupertinoIcons.delete, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        HapticFeedback.mediumImpact(); // Regla 5: Haptics
        setState(() {
          // Si eliminamos a un padre, opcionalmente eliminamos sus hijos (Cascade delete)
          _misTareas.removeWhere((t) => t['parentId'] == tarea['id']);
          _misTareas.removeAt(realIndex);
        });
        LocalDbService.guardarTareas(_misTareas);
      },
      child: contenido,
    );

    if (!isSubtask)
      return dismissible
          .animate()
          .fade(duration: 300.ms)
          .slideX(begin: 0.05, end: 0);

    // Diseño nativo de "Ramas de Git" para Subtareas
    return IntrinsicHeight(
      child: Stack(
        children: [
          // Línea vertical central
          Positioned(
            left: 33,
            top: 0,
            bottom: isLastChild ? null : 0,
            height: isLastChild
                ? 24
                : null, // Si es el último, la línea solo llega a la mitad
            child: Container(width: 2, color: Colors.grey.withOpacity(0.25)),
          ),
          // Línea horizontal conectora (codo)
          Positioned(
            left: 33,
            top: 22,
            child: Container(
              width: 18,
              height: 2,
              decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.25),
                  borderRadius:
                      const BorderRadius.horizontal(right: Radius.circular(2))),
            ),
          ),
          // Desplazamiento del contenido de la subtarea
          Container(
            margin: const EdgeInsets.only(left: 34),
            child: dismissible,
          ),
        ],
      )
          .animate()
          .fade(duration: 300.ms)
          .slideX(begin: 0.05, end: 0, delay: 100.ms),
    );
  }
}
