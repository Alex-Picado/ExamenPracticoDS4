import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:examen/models/turno.dart';
import 'package:examen/widgets/atender_turno_dialog.dart';

/// Comprueba que el formulario exige seleccionar un turno.
void main() {
  testWidgets('Rechaza confirmar sin seleccionar un turno', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AtenderTurnoDialog(
          turnosLlamados: [
            Turno(
              id: 1,
              estado: 'llamado',
              fechaCreacion: DateTime(2026, 10, 15),
              fechaLlamado: DateTime(2026, 10, 15, 8),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Marcar atendido'));
    await tester.pumpAndSettle();

    expect(find.text('Selecciona un turno llamado.'), findsOneWidget);
  });
}
