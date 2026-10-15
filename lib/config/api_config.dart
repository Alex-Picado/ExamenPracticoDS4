/// Centraliza las direcciones del backend utilizadas por Flutter Web.
class ApiConfig {
  /// Dirección base de las operaciones HTTP.
  static const String baseUrl = 'http://127.0.0.1:3000';

  /// Dirección del canal de comunicación en tiempo real.
  static const String webSocketUrl = 'ws://127.0.0.1:3000/ws';
}
