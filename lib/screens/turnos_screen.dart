import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/atender_turno_dialog.dart';
import '../widgets/lista_turnos.dart';
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
  bool _atendiendoTurno = false;
  late final TiempoRealService _tiempoReal;
  StreamSubscription<Map<String, dynamic>>? _suscripcion;
  Timer? _temporizadorReconexion;
  bool _conectando = false;
  bool _conectado = false;

  /// Inicializa los servicios, consulta los turnos y abre el WebSocket.
  @override
  void initState() {
    super.initState();

    _servicio = widget.servicio ?? TurnosService();
    _tiempoReal = widget.tiempoReal ?? TiempoRealService();

    _consulta = _servicio.listarTurnos();

    unawaited(_conectarTiempoReal());
  }

  /// Abre el canal y solicita el estado actual al servidor.
  ///
  /// Libera la conexión anterior y evita intentos simultáneos.
  Future<void> _conectarTiempoReal() async {
    if (!mounted || _conectando) {
      return;
    }

    _conectando = true;
    _temporizadorReconexion?.cancel();
    _temporizadorReconexion = null;

    _actualizarConexion(false);

    try {
      await _suscripcion?.cancel();
      _suscripcion = null;

      await _tiempoReal.cerrar();

      if (!mounted) {
        return;
      }

      _suscripcion = _tiempoReal.conectar().listen(
        (evento) {
          if (evento['tipo'] == 'turnos_actualizados') {
            _actualizarConexion(true);
            _cargarTurnos();
          }
        },
        onError: (Object error) {
          debugPrint('Error de WebSocket: $error');
          _programarReconexion();
        },
        onDone: _programarReconexion,
        cancelOnError: true,
      );

      await _tiempoReal.sincronizar();
    } catch (error) {
      debugPrint('No se pudo conectar el WebSocket: $error');
      _programarReconexion();
    } finally {
      _conectando = false;
    }
  }

  /// Programa un único reintento después de perder la conexión.
  void _programarReconexion() {
    if (!mounted) {
      return;
    }

    _actualizarConexion(false);

    if (_temporizadorReconexion != null) {
      return;
    }

    _temporizadorReconexion = Timer(const Duration(seconds: 2), () {
      _temporizadorReconexion = null;
      unawaited(_conectarTiempoReal());
    });
  }

  /// Actualiza la disponibilidad del canal mientras la pantalla siga abierta.
  void _actualizarConexion(bool conectado) {
    if (!mounted || _conectado == conectado) {
      return;
    }

    setState(() {
      _conectado = conectado;
    });
  }

  /// Describe el estado de conexión para mostrarlo en la página.
  String _textoConexion() {
    if (_conectado) {
      return 'Tiempo real conectado';
    }

    return 'Sin conexión. Reintentando...';
  }

  /// Habilita una acción únicamente cuando el canal está disponible.
  VoidCallback? _accionConectada(VoidCallback accion) {
    if (!_conectado) {
      return null;
    }

    return accion;
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

  /// Consulta los turnos llamados y abre el formulario de atención.
  ///
  /// El backend vuelve a comprobar el estado antes de guardar el cambio.
  Future<void> _abrirFormularioAtencion() async {
    if (_atendiendoTurno) {
      return;
    }

    setState(() {
      _atendiendoTurno = true;
    });

    try {
      final turnos = await _servicio.listarTurnos();

      if (!mounted) {
        return;
      }

      final llamados = turnos
          .where((turno) => turno.estado == 'llamado')
          .toList();

      if (llamados.isEmpty) {
        _mostrarMensaje('No hay turnos llamados para atender.');
        return;
      }

      final id = await showDialog<int>(
        context: context,
        builder: (context) {
          return AtenderTurnoDialog(turnosLlamados: llamados);
        },
      );

      if (id == null || !mounted) {
        return;
      }

      final atendido = await _servicio.atenderTurno(id);

      _cargarTurnos();

      if (atendido) {
        _mostrarMensaje('Turno $id atendido.');
      } else {
        _mostrarMensaje(
          'El turno ya cambió de estado o no existe. Revisa la lista.',
        );
      }
    } catch (_) {
      _cargarTurnos();

      _mostrarMensaje(
        'No se pudo confirmar la atención. Revisa la lista antes de reintentar.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _atendiendoTurno = false;
        });
      }
    }
  }

  /// Construye el botón y evita abrir varios formularios simultáneamente.
  Widget _construirBotonAtender() {
    if (_atendiendoTurno) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.hourglass_empty),
        label: const Text('Procesando...'),
      );
    }

    return OutlinedButton.icon(
      onPressed: _accionConectada(_abrirFormularioAtencion),
      icon: const Icon(Icons.check_circle_outline),
      label: const Text('Atender turno'),
    );
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
      onPressed: _accionConectada(_llamarSiguiente),
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
      onPressed: _accionConectada(_registrarTurno),
      icon: const Icon(Icons.add),
      label: const Text('Registrar turno'),
    );
  }

  /// Libera el temporizador, la suscripción y los servicios de la pantalla.
  @override
  void dispose() {
    _temporizadorReconexion?.cancel();

    unawaited(_suscripcion?.cancel());
    unawaited(_tiempoReal.cerrar());

    _servicio.cerrar();
    super.dispose();
  }

  /// Construye las categorías y conserva la pestaña durante las actualizaciones.
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Gestión de turnos'),
              Text(_textoConexion(), style: const TextStyle(fontSize: 12)),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _construirBotonLlamar(),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _construirBotonAtender(),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pendientes'),
              Tab(text: 'Llamados'),
              Tab(text: 'Atendidos'),
            ],
          ),
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

            return TabBarView(
              children: [
                ListaTurnos(turnos: turnos, estado: 'pendiente'),
                ListaTurnos(turnos: turnos, estado: 'llamado'),
                ListaTurnos(turnos: turnos, estado: 'atendido'),
              ],
            );
          },
        ),
      ),
    );
  }
}
