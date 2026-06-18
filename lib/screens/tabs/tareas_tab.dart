import 'dart:ui';
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
    final tareasSafe = tareasRaw
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

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
                      color: isDark
                          ? Colors.grey[900]!.withOpacity(0.8)
                          : Colors.white.withOpacity(0.8),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                                    border: InputBorder.none,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  onChanged: (value) => setModalState(() {}),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_upward_rounded),
                                color: Theme.of(context).primaryColor,
                                disabledColor: Colors.grey,
                                onPressed: tareaController.text.trim().isEmpty
                                    ? null
                                    : () {
                                        HapticFeedback.lightImpact();
                                        setState(() {
                                          _misTareas.insert(0, {
                                            'titulo': tareaController.text
                                                .trim(),
                                            'completada': false,
                                            'fecha': fechaSel,
                                            'prioridad': esPrioridad.toString(),
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
                                Icons.calendar_today_outlined,
                                color: fechaSel == 'Hoy'
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                setModalState(() => esPrioridad = !esPrioridad);
                              },
                              icon: Icon(
                                esPrioridad ? Icons.flag : Icons.flag_outlined,
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Recordatorios',
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
            _mostrarCreadorDeTareas(context);
          },
          shape: const CircleBorder(),
          elevation: 4,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: const Icon(Icons.add),
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
                    padding: const EdgeInsets.fromLTRB(0, 20, 0, 120),
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
}
