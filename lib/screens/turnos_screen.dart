import 'package:flutter/material.dart';

import '../models/turno.dart';
import '../services/turnos_service.dart';

class TurnosScreen extends StatefulWidget {
  final TurnosService? servicio;

  const TurnosScreen({super.key, this.servicio});

  @override
  State<TurnosScreen> createState() => _TurnosScreenState();
}

class _TurnosScreenState extends State<TurnosScreen> {
  late final TurnosService _servicio;
  late Future<List<Turno>> _consulta;

  @override
  void initState() {
    super.initState();
    _servicio = widget.servicio ?? TurnosService();
    _consulta = _servicio.listarTurnos();
  }

  void _cargarTurnos() {
    setState(() {
      _consulta = _servicio.listarTurnos();
    });
  }

  @override
  void dispose() {
    _servicio.cerrar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de turnos')),
      body: FutureBuilder<List<Turno>>(
        future: _consulta,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No se pudieron cargar los turnos.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _cargarTurnos,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final turnos = snapshot.data ?? <Turno>[];

          if (turnos.isEmpty) {
            return const Center(child: Text('No hay turnos registrados.'));
          }

          return ListView.builder(
            itemCount: turnos.length,
            itemBuilder: (context, index) {
              final turno = turnos[index];

              return ListTile(
                leading: const Icon(Icons.confirmation_number),
                title: Text('Turno ${turno.id}'),
                subtitle: Text('Estado: ${turno.estado}'),
              );
            },
          );
        },
      ),
    );
  }
}
