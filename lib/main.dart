import 'package:flutter/material.dart';

import 'screens/turnos_screen.dart';

/// Inicia la aplicación web de gestión de turnos.
void main() {
  runApp(const MyApp());
}

/// Configura el tema y la pantalla principal de la aplicación.
class MyApp extends StatelessWidget {
  /// Crea el componente principal.
  const MyApp({super.key});

  /// Construye la aplicación con su configuración visual.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestión de turnos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const TurnosScreen(),
    );
  }
}
