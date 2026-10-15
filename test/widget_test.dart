import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:examen/models/turno.dart';
import 'package:examen/screens/turnos_screen.dart';
import 'package:examen/services/turnos_service.dart';

class _TurnosServiceVacio extends TurnosService {
  @override
  Future<List<Turno>> listarTurnos() async {
    return [];
  }
}

void main() {
  testWidgets('Muestra un mensaje cuando no hay turnos', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: TurnosScreen(servicio: _TurnosServiceVacio())),
    );

    await tester.pumpAndSettle();

    expect(find.text('Gestión de turnos'), findsOneWidget);
    expect(find.text('No hay turnos registrados.'), findsOneWidget);
  });
}
