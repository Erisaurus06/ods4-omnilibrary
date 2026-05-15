import 'package:flutter/material.dart';

class ReaderScreen extends StatefulWidget {
  final String titulo;
  final String fuente;

  const ReaderScreen({super.key, required this.titulo, required this.fuente});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  // Variables para controlar la experiencia de lectura
  double _fontSize = 18.0;
  Color _backgroundColor = const Color(0xFFFAFAFA); // Blanco roto por defecto
  Color _textColor = Colors.black87;

  // Función para cambiar el tema de lectura
  void _cambiarTema(String tema) {
    setState(() {
      if (tema == 'Claro') {
        _backgroundColor = const Color(0xFFFAFAFA);
        _textColor = Colors.black87;
      } else if (tema == 'Sepia') {
        _backgroundColor = const Color(
          0xFFF4ECD8,
        ); // Color pergamino/sepia elegante
        _textColor = const Color(0xFF4A3C31); // Café oscuro
      } else if (tema == 'Oscuro') {
        _backgroundColor = const Color(0xFF121212); // Negro suave
        _textColor = Colors.white70; // Blanco tenue para no lastimar la vista
      }
    });
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
        ],
      ),
      // BARRA INFERIOR DE CONTROLES (Minimalista)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _backgroundColor,
          border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
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
                      () => _fontSize = (_fontSize > 14) ? _fontSize - 2 : 14,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.text_increase, color: _textColor),
                    onPressed: () => setState(
                      () => _fontSize = (_fontSize < 30) ? _fontSize + 2 : 30,
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
                    color: const Color(0xFFF4ECD8),
                    onTap: () => _cambiarTema('Sepia'),
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
      body: SingleChildScrollView(
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
            // Aquí iría el texto real del artículo. Por ahora usamos un texto de prueba.
            Text(
              '''La educación es el arma más poderosa que puedes usar para cambiar el mundo.\n\nEl acceso a la información siempre ha sido un pilar fundamental para el desarrollo humano. Sin embargo, en la era digital, nos enfrentamos a un nuevo reto: la sobreinformación y la fragmentación del conocimiento.\n\nEste artículo explora cómo herramientas tecnológicas y plataformas centralizadas pueden democratizar el aprendizaje, eliminando barreras económicas y sociales. A través del Objetivo de Desarrollo Sostenible número 4, la comunidad global se ha comprometido a garantizar una educación inclusiva y equitativa de calidad.''',
              style: TextStyle(
                fontSize: _fontSize,
                height: 1.6, // Interlineado amplio para lectura cómoda
                color: _textColor.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
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
