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
    return Scaffold(
      backgroundColor: Colors.transparent, // Para que se vea el fondo global
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          _modoVistaApuntes == 0 ? 'Muro de Notas 📌' : 'Mis Tareas 📅',
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Modal para nueva tarea en desarrollo.'),
                ),
              );
              _mostrarCreadorDeTareas(context);
            }
          },
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: const Icon(Icons.add),
        ),
      ),
      body: _modoVistaApuntes == 0
          ? _construirMuroDeNotas()
          : _construirLibretaTareas(),
    );
  }

  Widget _construirMuroDeNotas() {
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
      // Fondo estilo pared/corcho/refrigerador
      decoration: BoxDecoration(
        color: Colors.blueGrey[50], // Tono de refrigerador o pared
        image: const DecorationImage(
          image: NetworkImage(
            'https://www.transparenttextures.com/patterns/white-wall.png',
          ),
          repeat: ImageRepeat.repeat,
        ),
      ),
      child: Column(
        children: [
          // Barra de Búsqueda Mágica
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: TextField(
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search, color: Colors.grey),
                      hintText: 'Buscar en mis apuntes...',
                      border: InputBorder.none,
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
                          'Toca el + para iniciar tu primer apunte.',
                          style: TextStyle(
                            color: Colors.blueGrey.withOpacity(0.4),
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
                      // Para asegurar que el índice correcto se edita/elimina
                      final realIndex = _misApuntes.indexOf(apunte);

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GestureDetector(
                            onTap: () => _mostrarCreadorDeApuntes(
                              context,
                              apunteExistente: apunte,
                              index: realIndex,
                            ),
                            onLongPress: () {
                              HapticFeedback.heavyImpact();
                              _confirmarEliminar(realIndex);
                            },
                            child: Hero(
                              tag: 'apunte_$realIndex',
                              child: Material(
                                color: Colors.transparent,
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    24,
                                    16,
                                    16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(apunte['color']!)),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 8,
                                        offset: const Offset(2, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        apunte['titulo']!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (apunte.containsKey('fecha')) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatearFecha(apunte['fecha']),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.black.withOpacity(
                                              0.4,
                                            ),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: Text(
                                          apunte['contenido']!,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            height: 1.4,
                                            color: Colors.black87,
                                          ),
                                          overflow: TextOverflow.fade,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Chincheta / Imán superior
                          Positioned(
                            top: -8,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.red[400],
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _construirLibretaTareas() {
    return Container(
      // Fondo simulando líneas de una mini libreta
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.yellow[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.only(top: 16, bottom: 120),
        itemCount: _misTareas.length,
        separatorBuilder: (context, index) =>
            Divider(color: Colors.blue[200], height: 1),
        itemBuilder: (context, index) {
          final tarea = _misTareas[index];
          final isCompletada = tarea['completada'] as bool;
          return ListTile(
            leading: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _misTareas[index]['completada'] = !isCompletada;
                });
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompletada ? Colors.green : Colors.grey,
                    width: 2,
          return Dismissible(
            key: Key('tarea_${tarea['titulo']}_$index'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red[400],
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            onDismissed: (_) {
              setState(() => _misTareas.removeAt(index));
              LocalDbService.guardarTareas(_misTareas);
            },
            child: ListTile(
              leading: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _misTareas[index]['completada'] = !isCompletada;
                  });
                  LocalDbService.guardarTareas(_misTareas);
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompletada ? Colors.green : Colors.grey,
                      width: 2,
                    ),
                    color: isCompletada ? Colors.green : Colors.transparent,
                  ),
                  color: isCompletada ? Colors.green : Colors.transparent,
                  child: isCompletada
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                child: isCompletada
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            title: Text(
              tarea['titulo'],
              style: TextStyle(
                fontSize: 16,
                decoration: isCompletada ? TextDecoration.lineThrough : null,
                color: isCompletada ? Colors.grey : Colors.black87,
              title: Text(
                tarea['titulo'],
                style: TextStyle(
                  fontSize: 16,
                  decoration: isCompletada ? TextDecoration.lineThrough : null,
                  color: isCompletada ? Colors.grey : Colors.black87,
                ),
              ),
            ),
            subtitle: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: isCompletada ? Colors.grey : Colors.redAccent,
                ),
                const SizedBox(width: 4),
                Text(
                  tarea['fecha'],
                  style: TextStyle(
                    fontSize: 12,
              subtitle: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: isCompletada ? Colors.grey : Colors.redAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    tarea['fecha'],
                    style: TextStyle(
                      fontSize: 12,
                      color: isCompletada ? Colors.grey : Colors.redAccent,
                    ),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.notifications_active_outlined,
                  color: Colors.blueAccent,
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.notifications_active_outlined,
                color: Colors.blueAccent,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Recordatorio programado con el calendario.'),
                    ),
                  );
                },
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Recordatorio programado con el calendario.'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _confirmarEliminar(int index) {
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
                                      'color': selectedColor,
                                    };
                                  } else {
                                    _misFlashcards.insert(0, {
                                      'titulo': titulo,
                                      'contenido': contenido,
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
    return GridView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _misFlashcards.length,
      itemBuilder: (context, index) {
        final flashcard = _misFlashcards[index];
        return _FlashcardItem(
          nota: flashcard,
          onLongPress: () => _confirmarEliminar(index),
          onEdit: () => _mostrarCreadorDeFlashcards(
            context,
            flashcardExistente: flashcard,
            index: index,
          ),
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
      // Si no hay documentos, mostramos una pantalla vacía elegante
      body: _documentos.isEmpty
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
            )
          // Si hay documentos, mostramos Cuadrícula o Lista según prefiera el usuario
          : _vistaCuadricula
          ? _construirVistaCuadricula()
          : _construirVistaLista(),
    );
  }

  // --- VISTA 1: LISTA (Con función de deslizar para borrar) ---
  Widget _construirVistaLista() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      itemCount: _documentos.length,
      itemBuilder: (context, index) {
        final doc = _documentos[index];

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
              onLongPress: () => _mostrarMenuDocumento(index),
            ),
          ),
        );
      },
    );
  }

  // --- VISTA 2: CUADRÍCULA (Estilo estantería) ---
  Widget _construirVistaCuadricula() {
    return GridView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.all(20.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Dos columnas
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75, // Proporción estilo libro
      ),
      itemCount: _documentos.length,
      itemBuilder: (context, index) {
        final doc = _documentos[index];
        return GestureDetector(
          onTap: () => _abrirLector(doc),
          onLongPress: () => _mostrarMenuDocumento(index),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor ?? Colors.grey,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  doc['esPdf'] == true
                      ? Icons.picture_as_pdf_rounded
                      : Icons.menu_book_rounded,
                  size: 50,
                  color: Theme.of(context).primaryColor.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    doc['titulo'],
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
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
