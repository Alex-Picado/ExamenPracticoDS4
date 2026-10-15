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

/// Simula un canal abierto y una respuesta de sincronización.
class _TiempoRealFalso extends TiempoRealService {
  StreamController<Map<String, dynamic>>? _eventos;

  /// Crea un flujo controlado sin abrir conexiones reales.
  @override
  Stream<Map<String, dynamic>> conectar() {
    final eventos = StreamController<Map<String, dynamic>>();
    _eventos = eventos;
    return eventos.stream;
  }

  /// Simula el aviso que provoca la consulta de turnos.
  @override
  Future<void> sincronizar() async {
    _eventos?.add({'tipo': 'turnos_actualizados'});
  }

  /// Libera el flujo utilizado durante la prueba.
  @override
  Future<void> cerrar() async {
    final eventos = _eventos;
    _eventos = null;
    await eventos?.close();
  }
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
    // Retira la pantalla y permite terminar la liberación de recursos.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
