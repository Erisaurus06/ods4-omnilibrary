import 'package:flutter/material.dart';
import 'package:omnilibrary/screens/reader_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/local_db_service.dart';
import 'dart:io';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/supabase_service.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:math' as math;
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indiceActual = 0; // Controla en qué pestaña estamos

  // Lista de pantallas actualizada con la nueva sección de Apuntes
  final List<Widget> _pantallas = [
    const _SeccionApuntes(),
    const _SeccionFlashcards(),
    const _SeccionBiblioteca(),
    const _SeccionAjustes(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody:
          true, // Esto permite que el contenido pase por debajo del menú para revelar el desenfoque
      body: IndexedStack(index: _indiceActual, children: _pantallas),
      // --- BARRA DE NAVEGACIÓN PREMIUM ---
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 25, // Desenfoque más profundo estilo iOS
            sigmaY: 25,
          ), // El nivel de desenfoque
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).cardColor.withOpacity(0.65), // Color semi-transparente
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 0.5,
                ), // Reflejo del cristal superior
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: BottomNavigationBar(
                  currentIndex: _indiceActual,
                  elevation: 0,
                  onTap: (indice) {
                    HapticFeedback.lightImpact(); // Vibración sutil premium
                    setState(() => _indiceActual = indice);
                  },
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.transparent,
                  selectedItemColor: Theme.of(context).primaryColor,
                  unselectedItemColor: Colors.grey[400],
                  showSelectedLabels: true,
                  showUnselectedLabels: true,
                  selectedLabelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  items: const [
                    // 1. Item de "Apuntes"
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.sticky_note_2_outlined),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.sticky_note_2),
                      ),
                      label: 'Apuntes',
                    ),
                    // 2. Item de "Flashcards"
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.style_outlined),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.style),
                      ),
                      label: 'Flashcards',
                    ),
                    // 3. Item de "Biblioteca"
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.book_outlined),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.book),
                      ),
                      label: 'Biblioteca',
                    ),
                    // 3. Item de "Ajustes" (se mantiene)
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.settings_outlined),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.settings),
                      ),
                      label: 'Ajustes',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- SECCIÓN 1: APUNTES (Funcionalidad de Post-its) ---

class _SeccionApuntes extends StatefulWidget {
  const _SeccionApuntes();

  @override
  State<_SeccionApuntes> createState() => _SeccionApuntesState();
}

class _SeccionApuntesState extends State<_SeccionApuntes> {
  // 2. Lista persistente de apuntes (Post-its)
  List<Map<String, String>> _misApuntes = [];

  String _searchQuery = '';

  int _modoVistaApuntes = 0; // 0: Muro de Notas, 1: Libreta de Tareas
  List<Map<String, dynamic>> _misTareas = [];

  @override
  void initState() {
    super.initState();
    _cargarApuntes();
  }

  void _cargarApuntes() {
    setState(() {
      _misApuntes = LocalDbService.obtenerNotas();
      _misTareas = LocalDbService.obtenerTareas(); // Cargamos tareas reales
      
      // Si la memoria está vacía (primera vez que usa la app), inyectamos un ejemplo
      if (_misApuntes.isEmpty) {
        _misApuntes = [
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
        LocalDbService.guardarNotas(_misApuntes); // Las guardamos en disco
      }
    });
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

  // 3. Método para mostrar el modal de creación de apuntes
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
              onSave: (titulo, contenido, color) {
                setState(() {
                  if (apunteExistente != null && index != null) {
                    _misApuntes[index] = {
                      'titulo': titulo,
                      'contenido': contenido,
                      'color': color,
                      'fecha':
                          apunteExistente['fecha'] ??
                          DateTime.now().toIso8601String(),
                    };
                  } else {
                    _misApuntes.insert(0, {
                      'titulo': titulo,
                      'contenido': contenido,
                      'color': color,
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

  // Modal para crear Tareas reales
  void _mostrarCreadorDeTareas(BuildContext context) {
    final tareaController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tareaController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: '¿Qué necesitas recordar?', border: InputBorder.none, hintStyle: TextStyle(fontSize: 18)),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (tareaController.text.isNotEmpty) {
                      setState(() { _misTareas.insert(0, {'titulo': tareaController.text, 'completada': false, 'fecha': 'Próximamente'}); });
                      LocalDbService.guardarTareas(_misTareas);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Theme.of(context).scaffoldBackgroundColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Añadir a mi lista', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent, // Para que se vea el fondo global
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          _modoVistaApuntes == 0 ? 'Mis Notas' : 'Recordatorios',
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.2,
          ),
        ),
        toolbarHeight: 120,
        centerTitle: false,
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
      // 4. Botón flotante para crear nuevas notas
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
          backgroundColor: Colors.amber.shade600, // Estilo Apple Notes
          foregroundColor: Colors.white,
          child: const Icon(Icons.edit_square),
        ),
      ),
      body: _modoVistaApuntes == 0
          ? _construirMuroDeNotas(isDark)
          : _construirLibretaTareas(isDark),
    );
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1C1C1E), const Color(0xFF000000)]
              : [const Color(0xFFF2F2F7), const Color(0xFFE5E5EA)],
        ),
      ),
      child: Column(
        children: [
          // Barra de Búsqueda Estilo iOS
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800.withOpacity(0.6) : Colors.grey.shade300.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
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
                        const SizedBox(height: 8),
                        Text(
                          'Toca el botón de redactar para crear una nota o tarea.',
                          style: TextStyle(
                            color: Colors.blueGrey.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  )
                : Expanded(
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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

                        return GestureDetector(
                          onTap: () {
                            if (esTarea) {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _misApuntes[realIndex]['completada'] = isCompletada ? 'false' : 'true';
                              });
                              LocalDbService.guardarNotas(_misApuntes);
                            } else {
                              _mostrarCreadorHibrido(
                                context,
                                apunteExistente: apunte,
                                index: realIndex,
                              );
                            }
                          },
                          onLongPress: () {
                            _confirmarEliminar(realIndex);
                          },
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: isCompletada ? 0.5 : 1.0,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: Theme.of(context).dividerColor.withOpacity(0.5),
                                  width: 0.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (esTarea) ...[
                                        Icon(
                                          isCompletada ? Icons.check_circle : Icons.radio_button_unchecked,
                                          size: 18,
                                          color: isCompletada ? Colors.green : Theme.of(context).primaryColor,
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Expanded(
                                        child: Text(
                                          apunte['titulo']?.isNotEmpty == true ? apunte['titulo']! : 'Nueva nota',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Theme.of(context).primaryColor,
                                            decoration: isCompletada ? TextDecoration.lineThrough : null,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    apunte.containsKey('fecha') ? _formatearFecha(apunte['fecha']) : '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (!esTarea)
                                    Expanded(
                                      child: Text(
                                        apunte['contenido']?.isNotEmpty == true ? apunte['contenido']! : 'No hay texto adicional',
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 1.4,
                                          color: Theme.of(context).primaryColor.withOpacity(0.8),
                                        ),
                                        maxLines: 4,
                                        overflow: TextOverflow.fade,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(int index) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Eliminar apunte',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Deseas eliminar este apunte?',
          style: TextStyle(
            color: Theme.of(context).primaryColor.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(ctx);
              setState(() {
                _misApuntes.removeAt(index);
              });
              LocalDbService.guardarNotas(_misApuntes);
            },
            child: const Text(
              'Sí',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- SECCIÓN 2: FLASHCARDS (Tarjetas giratorias de estudio) ---
class _SeccionFlashcards extends StatefulWidget {
  const _SeccionFlashcards();

  @override
  State<_SeccionFlashcards> createState() => _SeccionFlashcardsState();
}

class _SeccionFlashcardsState extends State<_SeccionFlashcards> {
  final _tituloController = TextEditingController();
  final _contenidoController = TextEditingController();
  final _mazoController = TextEditingController(); // Controlador para Categorías
  List<Map<String, String>> _misFlashcards = [];

  int _modoFlashcards =
      0; // 0: Mis Tarjetas, 1: Modo Estudio (Quiz), 2: Bloques de Notas

  bool _quizActivo = false;
  int _quizIndex = 0;
  List<Map<String, String>> _dueFlashcards = []; // Tarjetas que tocan repasar hoy

  @override
  void initState() {
    super.initState();
    _cargarFlashcards();
  }

  void _cargarFlashcards() {
    setState(() {
      _misFlashcards = LocalDbService.obtenerFlashcards();
    });
  }

  void _mostrarCreadorDeFlashcards(
    BuildContext context, {
    Map<String, String>? flashcardExistente,
    int? index,
  }) {
    String selectedColor =
        flashcardExistente?['color'] ?? '0xFF90CAF9'; // Azul pastel por defecto
    _tituloController.text = flashcardExistente?['titulo'] ?? '';
    _contenidoController.text = flashcardExistente?['contenido'] ?? '';
    _mazoController.text = flashcardExistente?['mazo'] ?? 'General';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children:
                              [
                                '0xFFFFF59D',
                                '0xFFB39DDB',
                                '0xFFA5D6A7',
                                '0xFF90CAF9',
                                '0xFFFFAB91',
                              ].map((colorHex) {
                                final isSelected = selectedColor == colorHex;
                                return GestureDetector(
                                  onTap: () => setModalState(
                                    () => selectedColor = colorHex,
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: isSelected ? 40 : 32,
                                    height: isSelected ? 40 : 32,
                                    decoration: BoxDecoration(
                                      color: Color(int.parse(colorHex)),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? Theme.of(context).primaryColor
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _tituloController,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Concepto (Frente)',
                            border: InputBorder.none,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _mazoController,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                          decoration: InputDecoration(
                            icon: Icon(Icons.folder, color: Theme.of(context).primaryColor.withOpacity(0.5)),
                            hintText: 'Mazo o Categoría (Ej. Biología)',
                            border: InputBorder.none,
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const Divider(),
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.4,
                          ),
                          child: SingleChildScrollView(
                            child: TextField(
                              controller: _contenidoController,
                              maxLines: null,
                              minLines: 5,
                              style: const TextStyle(fontSize: 16, height: 1.5),
                              decoration: const InputDecoration(
                                hintText: 'Respuesta / Apunte (Reverso)...',
                                border: InputBorder.none,
                              ),
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              final titulo = _tituloController.text;
                              final contenido = _contenidoController.text;
                              if (titulo.isNotEmpty && contenido.isNotEmpty) {
                                setState(() {
                                  if (flashcardExistente != null &&
                                      index != null) {
                                    _misFlashcards[index] = {
                                      ...flashcardExistente, // Conserva datos de SRS previos
                                      'titulo': titulo,
                                      'contenido': contenido,
                                      'mazo': _mazoController.text.trim().isEmpty ? 'General' : _mazoController.text.trim(),
                                      'color': selectedColor,
                                    };
                                  } else {
                                    _misFlashcards.insert(0, {
                                      'titulo': titulo,
                                      'contenido': contenido,
                                      'mazo': _mazoController.text.trim().isEmpty ? 'General' : _mazoController.text.trim(),
                                      'color': selectedColor,
                                      'reps': '0',
                                      'ease': '2.5',
                                      'interval': '0',
                                      'nextReview': DateTime.now().toIso8601String(), // Repasar inmediatamente
                                    });
                                  }
                                });
                                LocalDbService.guardarFlashcards(
                                  _misFlashcards,
                                );
                                _tituloController.clear();
                                _contenidoController.clear();
                                _mazoController.clear();
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Theme.of(
                                context,
                              ).scaffoldBackgroundColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              flashcardExistente != null
                                  ? 'Actualizar Flashcard'
                                  : 'Crear Flashcard',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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

  void _confirmarEliminar(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Eliminar Flashcard',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Deseas eliminar esta tarjeta de memoria?',
          style: TextStyle(
            color: Theme.of(context).primaryColor.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _misFlashcards.removeAt(index));
              LocalDbService.guardarFlashcards(_misFlashcards);
            },
            child: const Text(
              'Sí',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          _modoFlashcards == 0
              ? 'Flashcards 🎴'
              : _modoFlashcards == 1
              ? 'Modo Estudio 🧠'
              : 'Bloques de Notas 📚',
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.2,
          ),
        ),
        toolbarHeight: 120,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Tarjetas'),
                    selected: _modoFlashcards == 0,
                    onSelected: (val) => setState(() => _modoFlashcards = 0),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Quizlet / Estudio'),
                    selected: _modoFlashcards == 1,
                    onSelected: (val) => setState(() => _modoFlashcards = 1),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Apuntes de Estudio'),
                    selected: _modoFlashcards == 2,
                    onSelected: (val) => setState(() => _modoFlashcards = 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          onPressed: () => _modoFlashcards == 0
              ? _mostrarCreadorDeFlashcards(context)
              : null,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: const Icon(Icons.add),
        ),
      ),
      body: _modoFlashcards == 0
          ? _construirGridTarjetas()
          : _modoFlashcards == 1
          ? _construirModoEstudio()
          : _construirBloquesNotas(),
    );
  }

  Widget _construirGridTarjetas() {
    final mazos = _misFlashcards.map((f) => f['mazo'] ?? 'General').toSet().toList();

    if (_misFlashcards.isEmpty) {
      return Center(
        child: Text('Tus flashcards aparecerán aquí organizadas por mazos.', style: TextStyle(color: Theme.of(context).primaryColor.withOpacity(0.5))),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 120),
      itemCount: mazos.length,
      itemBuilder: (context, index) {
        final mazo = mazos[index];
        final tarjetasMazo = _misFlashcards.where((f) => (f['mazo'] ?? 'General') == mazo).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.folder_open, color: Theme.of(context).primaryColor.withOpacity(0.7)),
                  const SizedBox(width: 8),
                  Text(
                    mazo,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${tarjetasMazo.length}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: tarjetasMazo.length,
                itemBuilder: (context, cardIndex) {
                  final flashcard = tarjetasMazo[cardIndex];
                  final realIndex = _misFlashcards.indexOf(flashcard);
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: _FlashcardItem(
                      nota: flashcard,
                      onLongPress: () => _confirmarEliminar(realIndex),
                      onEdit: () => _mostrarCreadorDeFlashcards(
                        context,
                        flashcardExistente: flashcard,
                        index: realIndex,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _construirModoEstudio() {
    if (_misFlashcards.isEmpty) {
      return Center(child: Text('Agrega flashcards primero para estudiar.', style: TextStyle(color: Theme.of(context).primaryColor.withOpacity(0.5))));
    }

    // Filtrar tarjetas que deben repasarse hoy (o que están atrasadas)
    final now = DateTime.now();
    final pendientes = _misFlashcards.where((fc) {
      final nextReviewStr = fc['nextReview'];
      if (nextReviewStr == null) return true; // Si es vieja sin algoritmo, es pendiente
      final nextReview = DateTime.tryParse(nextReviewStr) ?? now;
      return nextReview.isBefore(now) || nextReview.isAtSameMomentAs(now);
    }).toList();

    if (!_quizActivo) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 16),
            const Text(
              'Modo Estudio Interactivo',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'El algoritmo calculará cuándo debes\nvolver a ver cada tarjeta.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (pendientes.isNotEmpty)
              Text(
                'Tienes ${pendientes.length} tarjetas pendientes para hoy.',
                style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
              )
            else
              const Text(
                '¡Todo al día! No tienes tarjetas pendientes. 🎉',
                style: TextStyle(fontSize: 16, color: Colors.orangeAccent, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: pendientes.isEmpty ? null : () {
                  setState(() {
                    _dueFlashcards = pendientes;
                    _quizActivo = true;
                    _quizIndex = 0;
                  });
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar Repaso'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final flashcard = _dueFlashcards[_quizIndex];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Repaso ${_quizIndex + 1} de ${_dueFlashcards.length}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor.withOpacity(0.5))),
        const SizedBox(height: 24),
        SizedBox(
          height: 380,
          width: MediaQuery.of(context).size.width * 0.8,
          child: _FlashcardItem(nota: flashcard, onLongPress: (){}, onEdit: (){}), // Reutilizamos nuestra bella tarjeta 3D
        ),
        const SizedBox(height: 30),
        const Text('¿Qué tan fácil fue recordar esto?', style: TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCalificacionBtn('Difícil', Colors.redAccent, 2),
            _buildCalificacionBtn('Bien', Colors.blueAccent, 4),
            _buildCalificacionBtn('Fácil', Colors.green, 5),
          ],
        ),
      ],
    );
  }

  Widget _buildCalificacionBtn(String label, Color color, int calidad) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.15),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
        ),
      ),
      onPressed: () {
        HapticFeedback.lightImpact();
        _procesarRespuesta(calidad);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  // Implementación de Algoritmo de Repetición Espaciada (SM-2 Simplificado)
  void _procesarRespuesta(int calidad) {
    final currentCard = _dueFlashcards[_quizIndex];
    final originalIndex = _misFlashcards.indexOf(currentCard);
    if (originalIndex == -1) return; // Por si acaso

    int reps = int.tryParse(currentCard['reps'] ?? '0') ?? 0;
    double ease = double.tryParse(currentCard['ease'] ?? '2.5') ?? 2.5;
    int interval = int.tryParse(currentCard['interval'] ?? '0') ?? 0;

    if (calidad < 3) {
      // Fallaste o fue muy difícil. Reseteamos la racha y lo verás en 1 día.
      reps = 0;
      interval = 1;
    } else {
      // Lo recordaste
      if (reps == 0) {
        interval = 1;
      } else if (reps == 1) {
        interval = 6;
      } else {
        interval = (interval * ease).round();
      }
      reps++;
    }

    // Ajustamos la facilidad (ease factor)
    ease = ease + (0.1 - (5 - calidad) * (0.08 + (5 - calidad) * 0.02));
    if (ease < 1.3) ease = 1.3; // Límite inferior para evitar intervalos estancados

    final nextReview = DateTime.now().add(Duration(days: interval));

    setState(() {
      _misFlashcards[originalIndex] = {
        ...currentCard,
        'reps': reps.toString(),
        'ease': ease.toString(),
        'interval': interval.toString(),
        'nextReview': nextReview.toIso8601String(),
      };

      // Avanzamos en el mazo
      if (_quizIndex < _dueFlashcards.length - 1) {
        _quizIndex++;
      } else {
        _quizActivo = false; // Terminamos
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Sesión de estudio completada por hoy! 🎉🧠'),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      }
    });

    // Guardamos la memoria a largo plazo en disco
    LocalDbService.guardarFlashcards(_misFlashcards);
  }

  Widget _construirBloquesNotas() {
    return Center(
      child: Text(
        'Aquí se mostrarán tus bloques de notas estructuradas\npara repasar antes del Quiz.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    if (_misFlashcards.isEmpty) {
      return Center(child: Text('Tus bloques de estudio se verán aquí.', style: TextStyle(color: Theme.of(context).primaryColor.withOpacity(0.5))));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      physics: const BouncingScrollPhysics(),
      itemCount: _misFlashcards.length,
      separatorBuilder: (c, i) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final nota = _misFlashcards[index];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(int.parse(nota['color']!)).withOpacity(0.15), // Color pastel tenue
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(int.parse(nota['color']!)).withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(int.parse(nota['color']!)), size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(nota['titulo']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
              Text(nota['contenido']!, style: const TextStyle(fontSize: 15, height: 1.5)),
            ],
          ),
        );
      },
    );
  }
}

// --- WIDGET EXCLUSIVO DE FLASHCARD ANIMADA ---
class _FlashcardItem extends StatefulWidget {
  final Map<String, String> nota;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;

  const _FlashcardItem({
    required this.nota,
    required this.onLongPress,
    required this.onEdit,
  });

  @override
  State<_FlashcardItem> createState() => _FlashcardItemState();
}

class _FlashcardItemState extends State<_FlashcardItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    HapticFeedback.lightImpact();
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * math.pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspectiva 3D
            ..rotateY(angle);

          final isBackShowing = angle > math.pi / 2;

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(int.parse(widget.nota['color']!)),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isBackShowing
                  ? Transform(
                      transform: Matrix4.identity()
                        ..rotateY(
                          math.pi,
                        ), // Para que el texto no se vea en espejo
                      alignment: Alignment.center,
                      child: Stack(
                        children: [
                          Center(
                            child: SingleChildScrollView(
                              child: Text(
                                widget.nota['contenido']!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          Positioned(
                            top: -12,
                            right: -12,
                            child: IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.black54,
                                size: 20,
                              ),
                              onPressed: widget.onEdit,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Center(
                                child: Text(
                                  widget.nota['titulo']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.flip_camera_android,
                              color: Colors.black.withOpacity(0.2),
                              size: 20,
                            ),
                          ],
                        ),
                        Positioned(
                          top: -12,
                          right: -12,
                          child: IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.black54,
                              size: 20,
                            ),
                            onPressed: widget.onEdit,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

// --- SECCIÓN 4: AJUSTES (Configuración y APIs) ---

void _mostrarVincularGoogleBooks(BuildContext context) {
  // The GoogleSignIn instance is a singleton.
  final GoogleSignIn googleSignIn = GoogleSignIn.instance;

  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.library_books, size: 60, color: Colors.blue[400]),
            const SizedBox(height: 16),
            Text(
              'Vincular Google Play Books',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Al vincular tu cuenta, OmniLibrary podrá acceder a tus libros comprados y ePubs sincronizados usando la API oficial de Google Books OAuth 2.0.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).primaryColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.login),
                label: const Text('Autenticar con Google'),
                onPressed: () async {
                  try {
                    // The `signIn` method is now `authenticate`, and scopes are passed here.
                    final account = await googleSignIn.authenticate(
                      scopeHint: [
                        'email',
                        'https://www.googleapis.com/auth/books',
                      ],
                    );

                    Navigator.pop(context); // Cierra el modal inferior
                    // `authenticate` throws on failure, so `account` will not be null here.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Vinculado con éxito a: ${account.email}',
                        ),
                      ),
                    );
                    // OPCIONAL: Guarda `account.authHeaders` o el Token para inyectarlo en tus peticiones a la API
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al conectar con Google: $e'),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SeccionAjustes extends StatefulWidget {
  const _SeccionAjustes();

  @override
  State<_SeccionAjustes> createState() => _SeccionAjustesState();
}

class _SeccionAjustesState extends State<_SeccionAjustes> {
  bool _modoLectura = true;
  String _cacheSize = 'Calculando...';

  @override
  void initState() {
    super.initState();
    _actualizarTamanoCache();
  }

  void _actualizarTamanoCache() {
    setState(() {
      try {
        _cacheSize = LocalDbService.obtenerTamanoCache();
      } catch (e) {
        _cacheSize = '0 MB';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Configuración',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.2,
          ),
        ),
        centerTitle: false,
        toolbarHeight: 80,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        children: [
          // Perfil Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.grey.shade900, Colors.black]
                    : [Colors.blue.shade50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.grey.shade800 : Colors.blue.shade100,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Icon(Icons.person, size: 36, color: Theme.of(context).scaffoldBackgroundColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mi Cuenta',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        SupabaseService.client.auth.currentUser?.email ?? 'Usuario Invitado',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).primaryColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // --- 1. CUENTA ---
          _buildSectionHeader('CUENTA'),
          _buildSettingsCard(context, [
            _ActionTile(
              titulo: 'Sincronización en la Nube',
              icono: Icons.cloud_sync,
              colorIcono: Colors.indigo,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sincronización activada.')),
                );
              },
            ),
            _buildDivider(context),
            _ActionTile(
              titulo: 'Cerrar Sesión',
              icono: Icons.logout,
              colorIcono: Colors.redAccent,
              onTap: () => _confirmarCerrarSesion(context),
            ),
          ]),
          
          const SizedBox(height: 32),
          // --- 2. APARIENCIA ---
          _buildSectionHeader('APARIENCIA'),
          _buildSettingsCard(context, [
            _SwitchTile(
              titulo: 'Modo Oscuro',
              subtitulo: 'Cambia el tema visual',
              icono: Icons.dark_mode_rounded,
              valor: themeProvider.isDarkMode,
              onChanged: (val) => themeProvider.toggleTheme(val),
            ),
            _buildDivider(context),
            _SwitchTile(
              titulo: 'Modo Lectura',
              subtitulo: 'Optimiza el contraste y fuentes',
              icono: Icons.menu_book_rounded,
              valor: _modoLectura,
              onChanged: (val) => setState(() => _modoLectura = val),
            ),
          ]),
          
          const SizedBox(height: 32),
          // --- 3. INTEGRACIONES Y APIS ---
          _buildSectionHeader('INTEGRACIONES Y APIS'),
          _buildSettingsCard(context, [
            _ApiTile(
              titulo: 'Google Play Books',
              subtitulo: 'Sincroniza tu biblioteca',
              icono: Icons.library_books_rounded,
              conectado: false,
              onTap: () => _mostrarVincularGoogleBooks(context),
            ),
          ]),

          const SizedBox(height: 32),
          // --- 4. ALMACENAMIENTO Y DATOS ---
          _buildSectionHeader('ALMACENAMIENTO Y DATOS'),
          _buildSettingsCard(context, [
            _ActionTile(
              titulo: 'Espacio Ocupado',
              icono: Icons.storage_rounded,
              colorIcono: Colors.green,
              trailingText: _cacheSize,
              onTap: () {},
            ),
            _buildDivider(context),
            _ActionTile(
              titulo: 'Borrar Caché Local',
              icono: Icons.delete_sweep_rounded,
              colorIcono: Colors.orange,
              onTap: () async {
                await LocalDbService.limpiarCache();
                _actualizarTamanoCache();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Caché eliminada correctamente 🧹'),
                    backgroundColor: Theme.of(context).cardColor,
                  ),
                );
              },
            ),
          ]),

          const SizedBox(height: 32),
          // --- 5. ACERCA DE ---
          _buildSectionHeader('ACERCA DE'),
          _buildSettingsCard(context, [
            _ActionTile(
              titulo: 'Versión del Sistema',
              icono: Icons.info_outline_rounded,
              colorIcono: Colors.blueGrey,
              trailingText: Platform.operatingSystemVersion.split(' ').first,
              onTap: () {},
            ),
            _buildDivider(context),
            _ActionTile(
              titulo: 'Términos y Privacidad',
              icono: Icons.shield_outlined,
              colorIcono: Colors.teal,
              onTap: () async {
                final uri = Uri.parse('https://www.google.com/policies/privacy/');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.inAppWebView);
                }
              },
            ),
          ]),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ]
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      color: Theme.of(context).dividerColor.withOpacity(0.5),
    );
  }

  void _confirmarCerrarSesion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cerrar Sesión',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Estás seguro de que deseas salir de tu cuenta?',
          style: TextStyle(
            color: Theme.of(context).primaryColor.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Salir',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await SupabaseService.client.auth.signOut();
    }
  }
}

class _SwitchTile extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final bool valor;
  final Function(bool) onChanged;

  const _SwitchTile({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      activeColor: Theme.of(context).primaryColor,
      title: Text(
        titulo,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      subtitle: Text(
        subtitulo,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).primaryColor.withOpacity(0.6),
        ),
      ),
      secondary: Container(
        // Cuadro redondeado estilo Apple Settings
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icono,
          color: Theme.of(context).scaffoldBackgroundColor,
          size: 20,
        ),
      ),
      value: valor,
      onChanged: onChanged,
    );
  }
}

class _ApiTile extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final bool conectado;
  final VoidCallback? onTap; // NUEVO: Permite hacer clic en la API

  const _ApiTile({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.conectado,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: conectado ? primaryColor : Colors.grey[400],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icono,
          color: Theme.of(context).scaffoldBackgroundColor,
          size: 20,
        ),
      ),
      title: Text(
        titulo,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      subtitle: Text(
        subtitulo,
        style: TextStyle(fontSize: 13, color: primaryColor.withOpacity(0.6)),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.withOpacity(0.5)),
      onTap: onTap,
    );
  }
}

// --- NUEVO TILE ESTILO iOS PARA ACCIONES GLOBALES ---
class _ActionTile extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color colorIcono;
  final String? trailingText;
  final VoidCallback onTap;

  const _ActionTile({
    required this.titulo,
    required this.icono,
    required this.colorIcono,
    this.trailingText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 2,
      ), // Más compacto estilo iOS
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: colorIcono,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icono, color: Colors.white, size: 20),
      ),
      title: Text(
        titulo,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText!,
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),
          if (trailingText != null) const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: Colors.grey.withOpacity(0.5)),
        ],
      ),
      onTap: onTap,
    );
  }
}

// --- SECCIÓN 2: BIBLIOTECA (Tus PDFs y Libros REALES) ---
class _SeccionBiblioteca extends StatefulWidget {
  const _SeccionBiblioteca();

  @override
  State<_SeccionBiblioteca> createState() => _SeccionBibliotecaState();
}

class _SeccionBibliotecaState extends State<_SeccionBiblioteca> {
  List<Map<String, dynamic>> _documentos = [];
  bool _vistaCuadricula = false; // Controla si vemos lista o grid
  String _searchQuery = ''; // Búsqueda local

  // Genera un gradiente único y elegante basado en el título del libro
  List<Color> _generarColoresPortada(String titulo) {
    final int hash = titulo.hashCode;
    final hue1 = (hash % 360).toDouble();
    final hue2 = ((hash * 13) % 360).toDouble();
    return [
      HSLColor.fromAHSL(1.0, hue1, 0.7, 0.4).toColor(),
      HSLColor.fromAHSL(1.0, hue2, 0.8, 0.2).toColor(),
    ];
  }

  @override
  void initState() {
    super.initState();
    _cargarBiblioteca();
  }

  // Ahora carga SOLO lo que realmente existe en la base de datos
  void _cargarBiblioteca() {
    final docsDB = LocalDbService.obtenerDocumentos();
    setState(() => _documentos = docsDB);
  }

  // --- NUEVO: Menú contextual para documentos ---
  void _mostrarMenuDocumento(int index) {
    final doc = _documentos[index];
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                doc['titulo'],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Abrir documento'),
              onTap: () {
                Navigator.pop(context);
                _abrirLector(doc);
              },
            ),
            // Solo muestra la opción de IA para PDFs locales
            if (doc['esPdf'] == true && doc['path'] != null)
              ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: const Text('Generar Flashcards con IA'),
                onTap: () {
                  Navigator.pop(context);
                  _generarFlashcardsDesdePdf(doc['path']);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                _borrarDocumento(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- NUEVO: Lógica para generar Flashcards desde un PDF ---
  Future<void> _generarFlashcardsDesdePdf(String path) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text("Analizando PDF con IA...", style: TextStyle(color: Theme.of(context).primaryColor)),
          ],
        ),
      ),
    );

    try {
      // --- ¡IMPORTANTE! ---
      // Para que esto funcione, necesitas añadir `pdf_text: ^0.5.0` a tu `pubspec.yaml`
      // y luego importar `import 'package:pdf_text/pdf_text.dart';`
      // Descomenta las 2 líneas siguientes cuando lo hayas hecho:
      // PDFDoc doc = await PDFDoc.fromPath(path);
      // final String text = await doc.text;

      // --- SIMULACIÓN DE TEXTO EXTRAÍDO (BORRAR DESPUÉS DE INSTALAR `pdf_text`) ---
      await Future.delayed(const Duration(seconds: 2));
      const String text = 'La fotosíntesis es el proceso en el cual la energía de la luz se convierte en energía química en forma de azúcares. El cerebro humano es el centro del sistema nervioso.';
      // --- FIN DE LA SIMULACIÓN ---

      if (text.trim().isEmpty) throw Exception("El PDF no contiene texto extraíble.");

      final aiService = AiTranslationService();
      final nuevasFlashcards = await aiService.getFlashcardsFromText(text);

      Navigator.pop(context); // Cerrar diálogo de carga
      // ... (código para procesar y guardar las flashcards)
    } catch (e) {
      Navigator.pop(context);
      // ... (código para manejar errores)
    }
  }

  // Método para eliminar un documento
  void _borrarDocumento(int index) async {
    await LocalDbService.eliminarDocumento(index);
    _cargarBiblioteca(); // Recargamos la interfaz

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
    Navigator.pop(context); // Cierra el menú inferior
    try {
      FilePickerResult? resultado = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensiones,
      );

      if (resultado != null && resultado.files.single.path != null) {
        final nuevoDoc = {
          'titulo': resultado.files.single.name,
          'descargado': true,
          'esPdf': esPdf,
          'esEpub': esEpub,
          'path': resultado.files.single.path,
          'url': null,
        };

        await LocalDbService.guardarDocumento(nuevoDoc);
        _cargarBiblioteca(); // Actualizamos la lista visual
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
            .where((d) => (d['titulo'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Biblioteca',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.2,
          ),
        ),
        toolbarHeight: 80,
        centerTitle: false,
        actions: [
          // Botón para alternar entre Lista y Cuadrícula
          IconButton(
            icon: Icon(
              _vistaCuadricula
                  ? Icons.view_list_rounded
                  : Icons.grid_view_rounded,
            ),
            tooltip: 'Cambiar vista',
            onPressed: () =>
                setState(() => _vistaCuadricula = !_vistaCuadricula),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 90.0,
        ), // ESTO SOLUCIONA LA ORIENTACIÓN Y OVERLAP CON EL MENÚ
        child:
            FloatingActionButton(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: const Icon(Icons.add),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  backgroundColor: Theme.of(context).cardColor,
                  builder: (context) => SafeArea(
                    child: Wrap(
                      children: [
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
                            Icons.picture_as_pdf,
                            color: Theme.of(context).primaryColor,
                          ),
                          title: Text(
                            'Añadir PDF',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          onTap: () => _agregarArchivoLocal(
                            esPdf: true,
                            esEpub: false,
                            extensiones: ['pdf'],
                          ),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.book,
                            color: Theme.of(context).primaryColor,
                          ),
                          title: Text(
                            'Añadir Libro (ePub)',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          onTap: () => _agregarArchivoLocal(
                            esPdf: false,
                            esEpub: true,
                            extensiones: ['epub'],
                          ),
                        ),
                      ],
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
      body: Column(
        children: [
          // Barra de Búsqueda Estilo iOS Glassmorphic
          Padding(
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
                      icon: Icon(Icons.search, color: Colors.grey, size: 20),
                      hintText: 'Buscar en mi biblioteca...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _documentos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_stories_outlined,
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
                          'Toca el botón + para añadir PDFs o ePubs.',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade().scale()
                : _vistaCuadricula
                    ? _construirVistaCuadricula(docsFiltrados)
                    : _construirVistaLista(docsFiltrados),
          ),
        ],
      ),
    );
  }

  // --- VISTA 1: LISTA (Con función de deslizar para borrar) ---
  Widget _construirVistaLista(List<Map<String, dynamic>> documentos) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      itemCount: documentos.length,
      itemBuilder: (context, index) {
        final doc = documentos[index];
        // Encontrar el índice real en _documentos para borrar/editar correctamente
        final realIndex = _documentos.indexOf(doc);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor ?? Colors.grey,
              ),
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
                      ? Icons.picture_as_pdf_outlined
                      : Icons.book_outlined,
                  color: Theme.of(context).primaryColor.withOpacity(0.6),
                ),
              ),
              title: Text(
                doc['titulo'],
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Theme.of(context).primaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                'Disponible offline',
                style: TextStyle(
                  color: Theme.of(context).primaryColor.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: Theme.of(context).primaryColor.withOpacity(0.3),
              ),
              onTap: () => _abrirLector(doc),
              onLongPress: () => _mostrarMenuDocumento(realIndex),
            ),
          ),
        ).animate().fade(duration: 300.ms).slideX(begin: 0.05, end: 0, delay: (index % 15 * 30).ms);
      },
    );
  }

  // --- VISTA 2: CUADRÍCULA (Estilo estantería) ---
  Widget _construirVistaCuadricula(List<Map<String, dynamic>> documentos) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120), // Padding extra abajo
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Dos columnas
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.70, // Proporción estilo libro clásico
      ),
      itemCount: documentos.length,
      itemBuilder: (context, index) {
        final doc = documentos[index];
        final realIndex = _documentos.indexOf(doc);
        
        return GestureDetector(
          onTap: () => _abrirLector(doc),
          onLongPress: () => _mostrarMenuDocumento(realIndex),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _generarColoresPortada(doc['titulo']),
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Marca de agua de fondo
                Positioned(
                  right: -15,
                  bottom: -15,
                  child: Icon(
                    doc['esPdf'] == true ? Icons.picture_as_pdf : Icons.menu_book,
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      Text(
                        doc['titulo'],
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate().fade(duration: 400.ms).scale(begin: const Offset(0.9, 0.9), delay: (index % 10 * 40).ms);
      },
    );
  }

  void _abrirLector(Map<String, dynamic> doc) {
    if (doc['path'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReaderScreen(
            titulo: doc['titulo'],
            fuente: 'Mi Biblioteca',
            documentPath: doc['path'],
            isPdf: doc['esPdf'] ?? false,
            isEpub: doc['esEpub'] ?? false,
          ),
        ),
      );
    }
  }
}

// --- WIDGET EDITOR DE APUNTES CON ANIMACIÓN HERO Y AUTO-GUARDADO ---
class _EditorApuntePantalla extends StatefulWidget {
  final Map<String, String>? apunteExistente;
  final int? index;
  final Function(String, String, String) onSave;

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
  Timer? _debounceTimer;

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

    _tituloController.addListener(_onTextChanged);
    _contenidoController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (_tituloController.text.isNotEmpty ||
          _contenidoController.text.isNotEmpty) {
        widget.onSave(
          _tituloController.text.isNotEmpty
              ? _tituloController.text
              : 'Sin título',
          _contenidoController.text,
          _selectedColor,
        );
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _tituloController.dispose();
    _contenidoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(
        0.4,
      ), // Fondo difuminado interactivo
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 300)
            Navigator.pop(context); // Gesto natural para cerrar
        },
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context); // Tocar fuera cierra la nota
        },
        child: Center(
          child: Hero(
            tag: 'apunte_${widget.index ?? "nuevo"}',
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () {}, // Previene el cierre si toca dentro de la nota
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.height * 0.65,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Color(int.parse(_selectedColor)),
                    borderRadius: BorderRadius.circular(24),
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
                      TextField(
                        controller: _tituloController,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Título...',
                          border: InputBorder.none,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const Divider(color: Colors.black12),
                      Expanded(
                        child: TextField(
                          controller: _contenidoController,
                          maxLines: null,
                          expands: true,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                          decoration: const InputDecoration(
                            hintText:
                                'Escribe tu nota (se guarda automáticamente)...',
                            border: InputBorder.none,
                          ),
                          textCapitalization: TextCapitalization.sentences,
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
