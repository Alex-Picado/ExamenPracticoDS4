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
  bool _creandoTurno = false;

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

  Future<void> _registrarTurno() async {
    if (_creandoTurno) {
      return;
    }

    setState(() {
      _creandoTurno = true;
    });

    try {
      await _servicio.crearTurno();

      if (!mounted) {
        return;
      }

      _cargarTurnos();

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Turno registrado.')));
    } catch (_) {
      if (!mounted) {
        return;
      }

      _cargarTurnos();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo confirmar el registro. Revisa la lista antes de reintentar.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _creandoTurno = false;
        });
      }
    }
  }

  Widget _construirBotonRegistro() {
    if (_creandoTurno) {
      return const FloatingActionButton.extended(
        onPressed: null,
        icon: Icon(Icons.hourglass_empty),
        label: Text('Registrando...'),
      );
    }

    return FloatingActionButton.extended(
      onPressed: _registrarTurno,
      icon: const Icon(Icons.add),
      label: const Text('Registrar turno'),
    );
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
      floatingActionButton: _construirBotonRegistro(),
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
            padding: const EdgeInsets.only(bottom: 80),
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
