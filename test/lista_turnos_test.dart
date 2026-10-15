import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:examen/models/turno.dart';
import 'package:examen/widgets/lista_turnos.dart';

/// Comprueba el filtrado y la presentación de la fecha de atención.
void main() {
  testWidgets('El historial muestra solo atendidos con fecha y hora', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListaTurnos(
            estado: 'atendido',
            turnos: [
              Turno(
                id: 1,
                estado: 'pendiente',
                fechaCreacion: DateTime(2026, 10, 15, 9),
              ),
              Turno(
                id: 2,
                estado: 'atendido',
                fechaCreacion: DateTime(2026, 10, 15, 9),
                fechaLlamado: DateTime(2026, 10, 15, 9, 15),
                fechaAtencion: DateTime(2026, 10, 15, 9, 30),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Turno 1'), findsNothing);
    expect(find.text('Turno 2'), findsOneWidget);
    expect(find.text('Atendido: 15/10/2026 09:30'), findsOneWidget);
  });
}
