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
    final tareasSafe =
        tareasRaw.map((e) => Map<String, dynamic>.from(e)).toList();

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withOpacity(0.85),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: SafeArea(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 5,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
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
                                      decoration: const InputDecoration(
                                        hintText: '¿Qué necesitas recordar?',
                                        border: InputBorder.none,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
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
                                                    esPrioridad.toString(),
                                              });
                                            });
                                            LocalDbService.guardarTareas(
                                              _misTareas,
                                            );
                                            Navigator.pop(context);
                                          },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    setModalState(() {
                                      fechaSel = fechaSel == 'Próximamente'
                                          ? 'Hoy'
                                          : 'Próximamente';
                                    });
                                  },
                                  icon: Icon(
                                    CupertinoIcons.calendar,
                                    color: fechaSel == 'Hoy'
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey,
                                  ),
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
                                        ? Colors.orange
                                        : Colors.grey,
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
          elevation: 4,
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
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tarea = tareasFiltradas[index];
                    final realIndex = _misTareas.indexOf(tarea);
                    final bool isCompletada = tarea['completada'] == true;
                    final isPrioridad = tarea['prioridad'] == 'true';
                    final fecha = tarea['fecha'] ?? 'Próximamente';

                    return Column(
                      children: [
                        Dismissible(
                          key: Key('tarea_${realIndex}_${tarea['titulo']}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            color: CupertinoColors.destructiveRed,
                            child: const Icon(
                              CupertinoIcons.delete,
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
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  child: Text(tarea['titulo'] ?? 'Nueva tarea'),
                                ),
                                if (!isCompletada &&
                                    (fecha != 'Próximamente' || isPrioridad))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Row(
                                      children: [
                                        if (fecha != 'Próximamente')
                                          Flexible(
                                            child: Text(
                                              fecha,
                                              style: const TextStyle(
                                                color: CupertinoColors
                                                    .destructiveRed,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        if (fecha != 'Próximamente' &&
                                            isPrioridad)
                                          const SizedBox(width: 8),
                                        if (isPrioridad)
                                          const Icon(
                                            CupertinoIcons.flag_fill,
                                            color: Colors.orange,
                                            size: 14,
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (index < tareasFiltradas.length - 1)
                          Divider(
                            height: 1,
                            indent: 64,
                            color:
                                Theme.of(context).dividerColor.withOpacity(0.2),
                            thickness: 0.5,
                          ),
                      ],
                    );
                  },
                  childCount: tareasFiltradas.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
