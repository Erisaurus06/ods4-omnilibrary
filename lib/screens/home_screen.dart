import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hub de Conocimiento'),
        actions: [
          // ¡Aquí está el guiño a tu otra app!
          IconButton(
            icon: const Icon(Icons.headphones),
            tooltip: 'Configurar en TecConnection',
            onPressed: () {
              // Más adelante programaremos el Deep Link para abrir TecConnection
              print("Abriendo TecConnection...");
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Aquí irán el buscador, NatGeo y el Súper Lector',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
