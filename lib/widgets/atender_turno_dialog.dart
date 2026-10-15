import 'package:flutter/material.dart';

import '../models/turno.dart';

/// Formulario que permite seleccionar un turno llamado para atenderlo.
///
/// Devuelve el identificador seleccionado al cerrar el diálogo.
class AtenderTurnoDialog extends StatefulWidget {
  /// Turnos llamados disponibles para seleccionar.
  final List<Turno> turnosLlamados;

  /// Crea el formulario con los turnos proporcionados por la pantalla.
  const AtenderTurnoDialog({super.key, required this.turnosLlamados});

  /// Crea el estado que conserva la selección y valida el formulario.
  @override
  State<AtenderTurnoDialog> createState() => _AtenderTurnoDialogState();
}

/// Mantiene la selección realizada por el funcionario.
class _AtenderTurnoDialogState extends State<AtenderTurnoDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _turnoSeleccionado;

  /// Exige seleccionar un turno antes de confirmar la atención.
  String? _validarTurno(int? valor) {
    if (valor == null) {
      return 'Selecciona un turno llamado.';
    }

    return null;
  }

  /// Valida el formulario y devuelve el identificador seleccionado.
  void _confirmar() {
    final formulario = _formKey.currentState;

    if (formulario == null || !formulario.validate()) {
      return;
    }

    Navigator.of(context).pop(_turnoSeleccionado);
  }

  /// Construye el selector de turnos y las acciones del formulario.
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Atender turno'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: DropdownButtonFormField<int>(
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Turno llamado',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final turno in widget.turnosLlamados)
                DropdownMenuItem<int>(
                  value: turno.id,
                  child: Text('Turno ${turno.id}'),
                ),
            ],
            onChanged: (valor) {
              setState(() {
                _turnoSeleccionado = valor;
              });
            },
            validator: _validarTurno,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _confirmar,
          child: const Text('Marcar atendido'),
        ),
      ],
    );
  }
}
