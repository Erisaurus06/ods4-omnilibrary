import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../services/local_db_service.dart';

List<Map<String, String>> _procesarFlashcardsEnFondo(
  List<Map<String, String>> rawData,
) {
  final flashcards = List<Map<String, String>>.from(rawData);
  flashcards.sort(
    (a, b) => (a['mazo'] ?? 'General').compareTo(b['mazo'] ?? 'General'),
  );
  return flashcards;
}

class SeccionFlashcards extends StatefulWidget {
  const SeccionFlashcards({super.key});

  @override
  State<SeccionFlashcards> createState() => _SeccionFlashcardsState();
}

class _SeccionFlashcardsState extends State<SeccionFlashcards> {
  final _tituloController = TextEditingController();
  final _contenidoController = TextEditingController();
  final _mazoController = TextEditingController();
  List<Map<String, String>> _misFlashcards = [];
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
    final procesado = await compute(_procesarFlashcardsEnFondo, raw);
    if (mounted) {
      setState(() {
        _misFlashcards = procesado;
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
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                              onTap: () =>
                                  setModalState(() => selectedColor = colorHex),
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
                          Icons.folder,
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
                              if (flashcardExistente != null && index != null) {
                                _misFlashcards[index] = {
                                  ...flashcardExistente,
                                  'titulo': titulo,
                                  'contenido': contenido,
                                  'mazo': _mazoController.text.trim().isEmpty
                                      ? 'General'
                                      : _mazoController.text.trim(),
                                  'color': selectedColor,
                                };
                              } else {
                                _misFlashcards.insert(0, {
                                  'titulo': titulo,
                                  'contenido': contenido,
                                  'mazo': _mazoController.text.trim().isEmpty
                                      ? 'General'
                                      : _mazoController.text.trim(),
                                  'color': selectedColor,
                                  'reps': '0',
                                  'ease': '2.5',
                                  'interval': '0',
                                  'nextReview': DateTime.now()
                                      .toIso8601String(),
                                });
                              }
                            });
                            LocalDbService.guardarFlashcards(_misFlashcards);
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
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
          : _modoFlashcards == 0
          ? _construirGridTarjetas()
          : _modoFlashcards == 1
          ? _construirModoEstudio()
          : _construirBloquesNotas(),
    );
  }

  Widget _construirGridTarjetas() {
    final mazos = _misFlashcards
        .map((f) => f['mazo'] ?? 'General')
        .toSet()
        .toList();
    if (_misFlashcards.isEmpty)
      return Center(
        child: Text(
          'Tus flashcards aparecerán aquí organizadas por mazos.',
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
                    Icons.folder_open,
                    color: Theme.of(context).primaryColor.withOpacity(0.7),
                  ),
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
          'Agrega flashcards primero para estudiar.',
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
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              const Text(
                '¡Todo al día! No tienes tarjetas pendientes. 🎉',
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
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar Repaso'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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
        Text(
          'Repaso ${_quizIndex + 1} de ${_dueFlashcards.length}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 380,
          width: MediaQuery.of(context).size.width * 0.8,
          child: _FlashcardItem(
            nota: flashcard,
            onLongPress: () {},
            onEdit: () {},
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          '¿Qué tan fácil fue recordar esto?',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
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
      if (reps == 0) {
        interval = 1;
      } else if (reps == 1) {
        interval = 6;
      } else {
        interval = (interval * ease).round();
      }
      reps++;
    }
    ease = ease + (0.1 - (5 - calidad) * (0.08 + (5 - calidad) * 0.02));
    if (ease < 1.3) ease = 1.3;

    final nextReview = DateTime.now().add(Duration(days: interval));
    setState(() {
      _misFlashcards[originalIndex] = {
        ...currentCard,
        'reps': reps.toString(),
        'ease': ease.toString(),
        'interval': interval.toString(),
        'nextReview': nextReview.toIso8601String(),
      };
      if (_quizIndex < _dueFlashcards.length - 1) {
        _quizIndex++;
      } else {
        _quizActivo = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Sesión de estudio completada por hoy! 🎉🧠'),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      }
    });
    LocalDbService.guardarFlashcards(_misFlashcards);
  }

  Widget _construirBloquesNotas() {
    if (_misFlashcards.isEmpty)
      return const Center(
        child: Text(
          'Aquí se mostrarán tus bloques de notas estructuradas\npara repasar antes del Quiz.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
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
            color: Color(int.parse(nota['color']!)).withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color(int.parse(nota['color']!)).withOpacity(0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Color(int.parse(nota['color']!)),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nota['titulo']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(),
              ),
              Text(
                nota['contenido']!,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ],
          ),
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
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
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
