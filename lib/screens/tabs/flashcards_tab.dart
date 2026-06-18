import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/local_db_service.dart';

List<Map<String, String>> _procesarFlashcardsEnFondo(
  List<Map<String, String>> rawData,
) {
  final flashcards = List<Map<String, String>>.from(rawData);
  flashcards.sort(
    (a, b) => (a['mazo'] ?? 'General').compareTo(b['mazo'] ?? 'General'),
  );
  return flashcards;
}

class FlashcardsTab extends StatefulWidget {
  const FlashcardsTab({super.key});
  @override
  State<FlashcardsTab> createState() => _FlashcardsTabState();
}

class _FlashcardsTabState extends State<FlashcardsTab> {
  final _tituloController = TextEditingController();
  final _contenidoController = TextEditingController();
  final _mazoController = TextEditingController();
  List<Map<String, String>> _misFlashcards = [];
  List<Map<String, String>> _misNotas = [];

  int _modoFlashcards = 0;
  bool _quizActivo = false;
  int _quizIndex = 0;
  List<Map<String, String>> _dueFlashcards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarFlashcards();
  }

  Future<void> _cargarFlashcards() async {
    await Future.delayed(const Duration(milliseconds: 250));
    final raw = LocalDbService.obtenerFlashcards();
    final rawNotas = LocalDbService.obtenerNotas();
    final procesado = await compute(_procesarFlashcardsEnFondo, raw);
    if (mounted) {
      setState(() {
        _misFlashcards = procesado;
        _misNotas = rawNotas;
        _isLoading = false;
      });
    }
  }

  void _mostrarCreadorDeFlashcards(
    BuildContext context, {
    Map<String, String>? flashcardExistente,
    int? index,
  }) {
    String selectedColor = flashcardExistente?['color'] ?? '0xFF90CAF9';
    _tituloController.text = flashcardExistente?['titulo'] ?? '';
    _contenidoController.text = flashcardExistente?['contenido'] ?? '';
    _mazoController.text = flashcardExistente?['mazo'] ?? 'General';

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
              color: Theme.of(context).cardColor.withOpacity(0.85),
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SafeArea(
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics()),
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
                                    color: Colors.grey.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              alignment: WrapAlignment.spaceEvenly,
                              spacing: 12,
                              children: [
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
                                icon: Icon(
                                  CupertinoIcons.folder_fill,
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.5),
                                ),
                                hintText: 'Mazo o Categoría (Ej. Biología)',
                                border: InputBorder.none,
                              ),
                              textCapitalization: TextCapitalization.words,
                            ),
                            const Divider(),
                            Container(
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.of(context).size.height * 0.4,
                              ),
                              child: SingleChildScrollView(
                                child: TextField(
                                  controller: _contenidoController,
                                  maxLines: null,
                                  minLines: 5,
                                  style: const TextStyle(
                                      fontSize: 16, height: 1.5),
                                  decoration: const InputDecoration(
                                    hintText: 'Respuesta / Apunte (Reverso)...',
                                    border: InputBorder.none,
                                  ),
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  final titulo = _tituloController.text;
                                  final contenido = _contenidoController.text;
                                  if (titulo.isNotEmpty &&
                                      contenido.isNotEmpty) {
                                    setState(() {
                                      final fcData = {
                                        ...(flashcardExistente ?? {}),
                                        'titulo': titulo,
                                        'contenido': contenido,
                                        'mazo':
                                            _mazoController.text.trim().isEmpty
                                                ? 'General'
                                                : _mazoController.text.trim(),
                                        'color': selectedColor,
                                        if (flashcardExistente == null) ...{
                                          'reps': '0',
                                          'ease': '2.5',
                                          'interval': '0',
                                          'nextReview':
                                              DateTime.now().toIso8601String(),
                                        },
                                      };
                                      if (flashcardExistente != null &&
                                          index != null) {
                                        _misFlashcards[index] = fcData;
                                      } else {
                                        _misFlashcards.insert(0, fcData);
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
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
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

  void _confirmarEliminar(int index) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(
          'Eliminar Flashcard',
        ),
        content: Text(
          '¿Deseas eliminar esta tarjeta?',
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
              setState(() => _misFlashcards.removeAt(index));
              LocalDbService.guardarFlashcards(_misFlashcards);
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

  void _mostrarCreadorDeApuntes(
    BuildContext context, {
    Map<String, String>? notaExistente,
    int? index,
  }) {
    final titleCtrl =
        TextEditingController(text: notaExistente?['titulo'] ?? '');
    final contentCtrl =
        TextEditingController(text: notaExistente?['contenido'] ?? '');
    String selectedColor =
        notaExistente?['color'] ?? '0xFFFBF0D9'; // Sepia por defecto

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), // Regla 1: Cristal Esmerilado
            child: Container(
              color: isDark ? Colors.black.withOpacity(0.75) : Colors.white.withOpacity(0.75), // Regla 1
              height: MediaQuery.of(context).size.height * 0.93,
              child: SafeArea(
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    return Column(
                      children: [
                        // Barra superior nativa iOS
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  HapticFeedback.lightImpact(); // Regla 5: Haptics
                                  Navigator.pop(context);
                                },
                                child: const Text('Cancelar',
                                    style: TextStyle(
                                        color: CupertinoColors.destructiveRed,
                                        fontSize: 17)),
                              ),
                              Text(notaExistente != null ? 'Editar Apunte' : 'Nuevo Apunte',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 17,
                                      color: Theme.of(context).primaryColor)),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  HapticFeedback.mediumImpact(); // Regla 5: Haptics
                                  final uuid = notaExistente?['id'] ??
                                      DateTime.now()
                                          .millisecondsSinceEpoch
                                          .toString();
                                  final titulo = titleCtrl.text.trim().isEmpty
                                      ? 'Sin título'
                                      : titleCtrl.text.trim();
                                  final contenido = contentCtrl.text;

                                  setState(() {
                                    final nuevaNota = {
                                      'id': uuid,
                                      'titulo': titulo,
                                      'contenido': contenido,
                                      'color': selectedColor,
                                      'fecha': DateTime.now().toIso8601String(),
                                    };
                                    final existingIndex = _misNotas.indexWhere((n) => n['id'] == uuid);
                                    if (existingIndex != -1) {
                                      _misNotas[existingIndex] = nuevaNota;
                                    } else {
                                      _misNotas.insert(0, nuevaNota);
                                    }
                                  });
                                  LocalDbService.guardarNotas(_misNotas);
                                  Navigator.pop(context);
                                },
                                child: Text(notaExistente != null ? 'Guardar' : 'Agregar',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 17,
                                        color: CupertinoColors.activeBlue)),
                              ),
                            ],
                          ),
                        ),
                        Container(height: 0.5, color: Colors.grey.withOpacity(0.3)),
                        // Barra de herramientas Rich Text
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade900.withOpacity(0.5) : Colors.grey.shade200.withOpacity(0.5),
                            border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.3), width: 0.5)),
                          ),
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(), // Regla 4: Bouncing Scroll
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              CupertinoButton(padding: const EdgeInsets.symmetric(horizontal: 12), onPressed: () => HapticFeedback.selectionClick(), child: Icon(CupertinoIcons.bold, color: Theme.of(context).primaryColor, size: 22)),
                              CupertinoButton(padding: const EdgeInsets.symmetric(horizontal: 12), onPressed: () => HapticFeedback.selectionClick(), child: Icon(CupertinoIcons.italic, color: Theme.of(context).primaryColor, size: 22)),
                              CupertinoButton(padding: const EdgeInsets.symmetric(horizontal: 12), onPressed: () => HapticFeedback.selectionClick(), child: Icon(CupertinoIcons.underline, color: Theme.of(context).primaryColor, size: 22)),
                              Padding(padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0), child: Container(width: 1, color: Colors.grey.withOpacity(0.4))),
                              CupertinoButton(padding: const EdgeInsets.symmetric(horizontal: 12), onPressed: () => HapticFeedback.selectionClick(), child: Icon(CupertinoIcons.list_bullet, color: Theme.of(context).primaryColor, size: 22)),
                              CupertinoButton(padding: const EdgeInsets.symmetric(horizontal: 12), onPressed: () => HapticFeedback.selectionClick(), child: Icon(CupertinoIcons.list_number, color: Theme.of(context).primaryColor, size: 22)),
                              Padding(padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0), child: Container(width: 1, color: Colors.grey.withOpacity(0.4))),
                              ...[
                                '0xFFFBF0D9', // Sepia
                                '0xFFFFFFFF', // Blanco
                                '0xFFFFF59D', // Amarillo
                                '0xFFA5D6A7', // Verde
                                '0xFF90CAF9', // Azul
                              ].map((colorHex) {
                                final isSelected = selectedColor == colorHex;
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick(); // Regla 5: Haptics
                                    setModalState(
                                        () => selectedColor = colorHex);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 12),
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Color(int.parse(colorHex)),
                                      shape: BoxShape.circle, // Regla 3: Formas
                                      border: Border.all(
                                        color: isSelected ? CupertinoColors.activeBlue : Colors.grey.withOpacity(0.3),
                                        width: isSelected ? 2.5 : 1,
                                      ),
                                      boxShadow: isSelected ? [
                                        BoxShadow(
                                          color: CupertinoColors.activeBlue.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )
                                      ] : null,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                        // Editor de texto (Rich Text simulado)
                        Expanded(
                          child: Container(
                            color: Color(int.parse(selectedColor)),
                            width: double.infinity,
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics()), // Regla 4: Bouncing Physics
                              padding: EdgeInsets.only(
                                left: 24,
                                right: 24,
                                top: 32,
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom +
                                        100,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: titleCtrl,
                                    style: const TextStyle(
                                      fontSize: 32, // Regla 2: Large Titles
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                      letterSpacing: -0.5,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Título del apunte',
                                      hintStyle: TextStyle(
                                          color: Colors.black.withOpacity(0.3),
                                          fontWeight: FontWeight.w800),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    maxLines: null,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: contentCtrl,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      height: 1.5,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Comienza a escribir tus apuntes aquí...',
                                      hintStyle: TextStyle(
                                          color: Colors.black.withOpacity(0.3)),
                                      border: InputBorder.none,
                                    ),
                                    maxLines: null,
                                    textCapitalization:
                                        TextCapitalization.sentences,
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
            ),
          ),
        );
      },
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
                  : 'Apuntes 📚',
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
                    label: const Text('Apuntes'),
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
          onPressed: () {
            HapticFeedback.lightImpact();
            if (_modoFlashcards == 0) {
              _mostrarCreadorDeFlashcards(context);
            } else if (_modoFlashcards == 2) {
              _mostrarCreadorDeApuntes(context);
            }
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
          : _modoFlashcards == 0
              ? _construirGridTarjetas()
              : _modoFlashcards == 1
                  ? _construirModoEstudio()
                  : _construirBloquesNotas(),
    );
  }

  Widget _construirGridTarjetas() {
    final mazos =
        _misFlashcards.map((f) => f['mazo'] ?? 'General').toSet().toList();
    if (_misFlashcards.isEmpty)
      return Center(
        child: Text(
          'Tus flashcards aparecerán aquí.',
          style: TextStyle(
            color: Theme.of(context).primaryColor.withOpacity(0.5),
          ),
        ),
      );

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 120),
      itemCount: mazos.length,
      itemBuilder: (context, index) {
        final mazo = mazos[index];
        final tarjetasMazo = _misFlashcards
            .where((f) => (f['mazo'] ?? 'General') == mazo)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.folder,
                    color: Theme.of(context).primaryColor.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      mazo,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${tarjetasMazo.length}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
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
    if (_misFlashcards.isEmpty)
      return Center(
        child: Text(
          'Agrega flashcards primero.',
          style: TextStyle(
            color: Theme.of(context).primaryColor.withOpacity(0.5),
          ),
        ),
      );

    final now = DateTime.now();
    final pendientes = _misFlashcards.where((fc) {
      final nextReviewStr = fc['nextReview'];
      if (nextReviewStr == null) return true;
      final nextReview = DateTime.tryParse(nextReviewStr) ?? now;
      return nextReview.isBefore(now) || nextReview.isAtSameMomentAs(now);
    }).toList();

    if (!_quizActivo) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.book_fill,
                size: 80, color: CupertinoColors.activeBlue),
            const SizedBox(height: 16),
            const Text(
              'Modo Estudio Interactivo',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (pendientes.isNotEmpty)
              Text(
                'Tienes ${pendientes.length} tarjetas pendientes para hoy.',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              const Text(
                '¡Todo al día! 🎉',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: pendientes.isEmpty
                  ? null
                  : () {
                      setState(() {
                        _dueFlashcards = pendientes;
                        _quizActivo = true;
                        _quizIndex = 0;
                      });
                    },
              icon: const Icon(CupertinoIcons.play_fill),
              label: const Text('Iniciar Repaso',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final flashcard = _dueFlashcards[_quizIndex];
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          'Repaso ${_quizIndex + 1} de ${_dueFlashcards.length}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Center(
              child: Dismissible(
                key: ValueKey('${flashcard['titulo']}_$_quizIndex'),
                direction: DismissDirection.horizontal,
                onDismissed: (direction) {
                  HapticFeedback.mediumImpact();
                  if (direction == DismissDirection.endToStart) {
                    _procesarRespuesta(2); // Swipe Izquierda -> Difícil
                  } else {
                    _procesarRespuesta(5); // Swipe Derecha -> Fácil
                  }
                },
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 32),
                  decoration: BoxDecoration(
                    color: CupertinoColors.activeGreen.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.checkmark_circle_fill,
                          color: Colors.white, size: 50),
                      const SizedBox(height: 8),
                      Flexible(
                        child: const Text('Fácil',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      ),
                    ],
                  ),
                ),
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 32),
                  decoration: BoxDecoration(
                    color: CupertinoColors.destructiveRed.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.xmark_circle_fill,
                          color: Colors.white, size: 50),
                      const SizedBox(height: 8),
                      Flexible(
                        child: const Text('Difícil',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      ),
                    ],
                  ),
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.55,
                  width: double.infinity,
                  child: _FlashcardItem(
                    nota: flashcard,
                    onLongPress: () {},
                    onEdit: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Desliza la tarjeta o usa los botones',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 120.0),
          child: Row(
            children: [
              Expanded(
                  child: _buildCalificacionBtn(
                      'Difícil', CupertinoColors.destructiveRed, 2)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildCalificacionBtn(
                      'Bien', CupertinoColors.activeBlue, 4)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildCalificacionBtn(
                      'Fácil', CupertinoColors.activeGreen, 5)),
            ],
          ),
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
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  void _procesarRespuesta(int calidad) {
    final currentCard = _dueFlashcards[_quizIndex];
    final originalIndex = _misFlashcards.indexOf(currentCard);
    if (originalIndex == -1) return;

    int reps = int.tryParse(currentCard['reps'] ?? '0') ?? 0;
    double ease = double.tryParse(currentCard['ease'] ?? '2.5') ?? 2.5;
    int interval = int.tryParse(currentCard['interval'] ?? '0') ?? 0;

    if (calidad < 3) {
      reps = 0;
      interval = 1;
    } else {
      if (reps == 0)
        interval = 1;
      else if (reps == 1)
        interval = 6;
      else
        interval = (interval * ease).round();
      reps++;
    }

    ease = ease + (0.1 - (5 - calidad) * (0.08 + (5 - calidad) * 0.02));
    if (ease < 1.3) ease = 1.3;

    setState(() {
      _misFlashcards[originalIndex] = {
        ...currentCard,
        'reps': reps.toString(),
        'ease': ease.toString(),
        'interval': interval.toString(),
        'nextReview':
            DateTime.now().add(Duration(days: interval)).toIso8601String(),
      };
      if (_quizIndex < _dueFlashcards.length - 1) {
        _quizIndex++;
      } else {
        _quizActivo = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Sesión completada! 🎉🧠'),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      }
    });
    LocalDbService.guardarFlashcards(_misFlashcards);
  }

  Widget _construirBloquesNotas() {
    if (_misNotas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.book,
                size: 80,
                color: Theme.of(context).primaryColor.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              'No tienes apuntes',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor.withOpacity(0.6)),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75, // Proporción visual de libreta
      ),
      itemCount: _misNotas.length,
      itemBuilder: (context, index) {
        final nota = _misNotas[index];
        final colorStr = nota['color'] ?? '0xFFFBF0D9';
        final color = Color(int.tryParse(colorStr) ?? 0xFFFBF0D9);

        return GestureDetector(
          onTap: () => _mostrarCreadorDeApuntes(context,
              notaExistente: nota, index: index),
          onLongPress: () {
            HapticFeedback.mediumImpact();
            showCupertinoModalPopup(
              context: context,
              builder: (ctx) => CupertinoActionSheet(
                title: Text(nota['titulo'] ?? 'Opciones de Apunte'),
                message: const Text('¿Qué deseas hacer con esta libreta?'),
                actions: [
                  CupertinoActionSheetAction(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(ctx);
                      final texto =
                          '${nota['titulo'] ?? 'Sin título'}\n\n${nota['contenido'] ?? ''}';
                      Share.share(texto, subject: nota['titulo']);
                    },
                    child: const Text('Exportar como Texto'),
                  ),
                  CupertinoActionSheetAction(
                    isDestructiveAction: true,
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(ctx);
                      setState(() => _misNotas.removeAt(index));
                      LocalDbService.guardarNotas(_misNotas);
                    },
                    child: const Text('Eliminar Apunte'),
                  ),
                ],
                cancelButton: CupertinoActionSheetAction(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(2, 4)),
              ],
            ),
            child: Stack(
              children: [
                // Lomo de la libreta
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nota['titulo'] ?? 'Sin título',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          nota['contenido'] ?? '',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.black.withOpacity(0.6),
                              height: 1.4),
                          overflow: TextOverflow.fade,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fade().scale(delay: (index % 10 * 50).ms),
        );
      },
    );
  }
}

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
    if (_isFront)
      _controller.forward();
    else
      _controller.reverse();
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
            ..setEntry(3, 2, 0.001)
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
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.black.withOpacity(0.05),
                  width: 1,
                ),
              ),
              child: isBackShowing
                  ? Transform(
                      transform: Matrix4.identity()..rotateY(math.pi),
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
                                CupertinoIcons.pencil,
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
                              CupertinoIcons.arrow_2_squarepath,
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
                              CupertinoIcons.pencil,
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
