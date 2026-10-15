import 'dart:async';

import 'package:flutter/material.dart';

import '../models/turno.dart';
import '../services/tiempo_real_service.dart';
import '../services/turnos_service.dart';

/// Página web para consultar y gestionar los turnos.
class TurnosScreen extends StatefulWidget {
  /// Servicio HTTP utilizado para consultar y modificar turnos.
  final TurnosService? servicio;

  /// Servicio WebSocket utilizado para recibir avisos de cambios.
  final TiempoRealService? tiempoReal;

  /// Permite proporcionar servicios controlados durante las pruebas.
  const TurnosScreen({super.key, this.servicio, this.tiempoReal});

  /// Crea el estado que mantiene la consulta y las conexiones.
  @override
  State<TurnosScreen> createState() => _TurnosScreenState();
}

class _TurnosScreenState extends State<TurnosScreen> {
  late final TurnosService _servicio;
  late Future<List<Turno>> _consulta;
  bool _creandoTurno = false;
  bool _llamandoTurno = false;
  late final TiempoRealService _tiempoReal;
  StreamSubscription<Map<String, dynamic>>? _suscripcion;

  /// Inicializa los servicios, consulta los turnos y abre el WebSocket.
  @override
  void initState() {
    super.initState();

    _servicio = widget.servicio ?? TurnosService();
    _tiempoReal = widget.tiempoReal ?? TiempoRealService();

    _consulta = _servicio.listarTurnos();

    unawaited(_conectarTiempoReal());
  }

  /// Escucha los avisos del servidor y solicita la sincronización inicial.
  ///
  /// Cada aviso de cambios provoca una consulta HTTP de los turnos.
  Future<void> _conectarTiempoReal() async {
    try {
      _suscripcion = _tiempoReal.conectar().listen(
        (evento) {
          if (evento['tipo'] == 'turnos_actualizados') {
            _cargarTurnos();
          }
        },
        onError: (Object error) {
          debugPrint('Error de WebSocket: $error');
        },
        onDone: () {
          debugPrint('Conexión WebSocket cerrada.');
        },
        cancelOnError: true,
      );

      await _tiempoReal.sincronizar();
    } catch (error) {
      debugPrint('No se pudo conectar el WebSocket: $error');
    }
  }

  /// Actualiza la consulta mientras la pantalla siga abierta.
  void _cargarTurnos() {
    if (!mounted) {
      return;
    }

    setState(() {
      _consulta = _servicio.listarTurnos();
    });
  }

  /// Registra un turno y evita solicitudes repetidas mientras se procesa.
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

  /// Solicita el siguiente turno y comunica el resultado al funcionario.
  ///
  /// Evita solicitudes repetidas mientras la llamada está en proceso.
  Future<void> _llamarSiguiente() async {
    if (_llamandoTurno) {
      return;
    }

    setState(() {
      _llamandoTurno = true;
    });

    try {
      final turno = await _servicio.llamarSiguiente();

      _cargarTurnos();

      if (turno == null) {
        _mostrarMensaje('No hay turnos pendientes.');
      } else {
        _mostrarMensaje('Se llamó al turno ${turno.id}.');
      }
    } catch (_) {
      _cargarTurnos();

      _mostrarMensaje(
        'No se pudo confirmar la llamada. Revisa la lista antes de reintentar.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _llamandoTurno = false;
        });
      }
    }
  }

  /// Muestra un aviso únicamente si la pantalla continúa abierta.
  void _mostrarMensaje(String mensaje) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  /// Construye el botón y lo deshabilita mientras se procesa la llamada.
  Widget _construirBotonLlamar() {
    if (_llamandoTurno) {
      return FilledButton.icon(
        onPressed: null,
        icon: const Icon(Icons.hourglass_empty),
        label: const Text('Llamando...'),
      );
    }

    return FilledButton.icon(
      onPressed: _llamarSiguiente,
      icon: const Icon(Icons.campaign),
      label: const Text('Llamar siguiente'),
    );
  }

  /// Construye el botón según el estado de la solicitud de registro.
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

  /// Libera la suscripción, el canal WebSocket y el cliente HTTP.
  @override
  void dispose() {
    unawaited(_suscripcion?.cancel());
    unawaited(_tiempoReal.cerrar());

    _servicio.cerrar();
    super.dispose();
  }

  /// Construye la página según el resultado de la consulta HTTP.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de turnos'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _construirBotonLlamar(),
          ),
        ],
      ),
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
