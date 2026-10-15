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

  void cerrar() {
    _cliente.close();
  }
}
