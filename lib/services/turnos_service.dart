import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/turno.dart';

class TurnosService {
  final http.Client _cliente = http.Client();

  Future<List<Turno>> listarTurnos() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/turnos');

    final respuesta = await _cliente
        .get(url)
        .timeout(const Duration(seconds: 10));

    if (respuesta.statusCode != 200) {
      throw Exception('No se pudieron consultar los turnos.');
    }

    final datos = jsonDecode(respuesta.body) as List<dynamic>;
    final turnos = <Turno>[];

    for (final dato in datos) {
      turnos.add(Turno.fromJson(dato as Map<String, dynamic>));
    }

    return turnos;
  }

  Future<void> crearTurno() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/turnos');

    final respuesta = await _cliente
        .post(url)
        .timeout(const Duration(seconds: 10));

    if (respuesta.statusCode != 201) {
      throw Exception('No se pudo registrar el turno.');
    }
  }


  /// Solicita al servidor que llame al primer turno pendiente.
  ///
  /// Devuelve null cuando no quedan turnos pendientes.
  /// El servidor selecciona y bloquea el turno para evitar duplicaciones.
  Future<Turno?> llamarSiguiente() async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/turnos/siguiente',
    );

    final respuesta = await _cliente
        .post(url)
        .timeout(const Duration(seconds: 10));

    if (respuesta.statusCode == 404) {
      return null;
    }

    if (respuesta.statusCode != 200) {
      throw Exception('No se pudo llamar al siguiente turno.');
    }

    final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;

    return Turno.fromJson(datos);
  }

  void cerrar() {
    _cliente.close();
  }
}
