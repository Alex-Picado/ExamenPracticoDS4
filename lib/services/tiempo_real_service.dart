import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/api_config.dart';

/// Gestiona el canal WebSocket y recibe los eventos del backend.
///
/// Las operaciones sobre los turnos se realizan mediante HTTP.
class TiempoRealService {
  /// Referencia al canal de la conexión actual.
  WebSocketChannel? _canal;

  /// Crea el servicio sin iniciar todavía una conexión.
  TiempoRealService();

  /// Abre una conexión y devuelve sus eventos convertidos desde JSON.
  ///
  /// El consumidor debe escuchar este flujo antes de llamar a [sincronizar].
  /// Rechaza una segunda conexión hasta que se cierre la anterior.
  Stream<Map<String, dynamic>> conectar() {
    if (_canal != null) {
      throw StateError('Ya existe una conexión WebSocket.');
    }

    final canal = WebSocketChannel.connect(Uri.parse(ApiConfig.webSocketUrl));

    _canal = canal;

    return canal.stream.map((mensaje) {
      final evento = jsonDecode(mensaje as String);

      if (evento is! Map<String, dynamic>) {
        throw const FormatException('El evento recibido no es un objeto JSON.');
      }

      return evento;
    });
  }

  /// Espera la conexión y solicita una notificación de sincronización.
  ///
  /// El backend responde con el evento `turnos_actualizados`.
  /// La pantalla deberá consultar entonces la lista mediante HTTP.
  Future<void> sincronizar() async {
    final canal = _canal;

    if (canal == null) {
      throw StateError('Primero debes abrir la conexión WebSocket.');
    }

    await canal.ready.timeout(const Duration(seconds: 10));

    if (_canal != canal) {
      return;
    }

    canal.sink.add(jsonEncode({'tipo': 'sincronizar'}));
  }

  /// Cierra el canal actual y permite abrir una nueva conexión después.
  Future<void> cerrar() async {
    final canal = _canal;
    _canal = null;

    if (canal != null) {
      await canal.sink.close();
    }
  }
}
