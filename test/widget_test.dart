import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:examen/models/turno.dart';
import 'package:examen/screens/turnos_screen.dart';
import 'package:examen/services/tiempo_real_service.dart';
import 'package:examen/services/turnos_service.dart';

/// Proporciona una lista vacía sin consultar el backend.
class _TurnosServiceVacio extends TurnosService {
  /// Devuelve los turnos controlados de esta prueba.
  @override
  Future<List<Turno>> listarTurnos() async {
    return [];
  }
}

/// Sustituye el WebSocket durante la prueba de la pantalla.
class _TiempoRealFalso extends TiempoRealService {
  /// Proporciona un flujo vacío sin abrir conexiones.
  @override
  Stream<Map<String, dynamic>> conectar() {
    return const Stream<Map<String, dynamic>>.empty();
  }

  /// Simula la solicitud de sincronización sin enviar mensajes.
  @override
  Future<void> sincronizar() async {}
}

/// Comprueba la presentación de una lista de turnos vacía.
void main() {
  testWidgets('Muestra un mensaje cuando no hay turnos', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TurnosScreen(
          servicio: _TurnosServiceVacio(),
          tiempoReal: _TiempoRealFalso(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Gestión de turnos'), findsOneWidget);
    expect(find.text('No hay turnos pendientes.'), findsOneWidget);
  });
}
