import 'package:flutter/material.dart';

import '../models/turno.dart';

/// Muestra los turnos de un estado y sus fechas correspondientes.
class ListaTurnos extends StatelessWidget {
  /// Lista completa recibida desde el backend.
  final List<Turno> turnos;

  /// Estado que debe mostrarse: pendiente, llamado o atendido.
  final String estado;

  /// Crea una lista filtrada por el estado indicado.
  const ListaTurnos({super.key, required this.turnos, required this.estado});

  /// Describe la ausencia de turnos en la categoría seleccionada.
  String _mensajeVacio() {
    if (estado == 'pendiente') {
      return 'No hay turnos pendientes.';
    }

    if (estado == 'llamado') {
      return 'No hay turnos llamados.';
    }

    return 'No hay turnos atendidos.';
  }

  /// Convierte una fecha a hora local con formato día/mes/año hora:minuto.
  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) {
      return 'Sin fecha registrada';
    }

    final local = fecha.toLocal();
    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    final hora = local.hour.toString().padLeft(2, '0');
    final minuto = local.minute.toString().padLeft(2, '0');

    return '$dia/$mes/${local.year} $hora:$minuto';
  }

  /// Obtiene la fecha relevante para el estado del turno.
  String _detalleTurno(Turno turno) {
    if (estado == 'atendido') {
      return 'Atendido: ${_formatearFecha(turno.fechaAtencion)}';
    }

    if (estado == 'llamado') {
      return 'Llamado: ${_formatearFecha(turno.fechaLlamado)}';
    }

    return 'Registrado: ${_formatearFecha(turno.fechaCreacion)}';
  }

  /// Filtra los turnos y construye la lista o el mensaje de categoría vacía.
  @override
  Widget build(BuildContext context) {
    final filtrados = turnos.where((turno) => turno.estado == estado).toList();

    if (filtrados.isEmpty) {
      return Center(child: Text(_mensajeVacio()));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: filtrados.length,
      itemBuilder: (context, index) {
        final turno = filtrados[index];

        return ListTile(
          leading: const Icon(Icons.confirmation_number),
          title: Text('Turno ${turno.id}'),
          subtitle: Text(_detalleTurno(turno)),
        );
      },
    );
  }
}
