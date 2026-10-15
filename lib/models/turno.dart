/// Representa un turno recibido desde la API.
class Turno {
  /// Número único asignado por la base de datos.
  final int id;

  /// Estado actual: pendiente, llamado o atendido.
  final String estado;

  /// Fecha en que se registró el turno.
  final DateTime fechaCreacion;

  /// Fecha de llamada; permanece vacía mientras esté pendiente.
  final DateTime? fechaLlamado;

  /// Fecha de atención; permanece vacía hasta completar la atención.
  final DateTime? fechaAtencion;

  /// Crea un turno con los datos proporcionados.
  const Turno({
    required this.id,
    required this.estado,
    required this.fechaCreacion,
    this.fechaLlamado,
    this.fechaAtencion,
  });

  /// Convierte los campos JSON del backend al modelo de Flutter.
  factory Turno.fromJson(Map<String, dynamic> json) {
    return Turno(
      id: json['id'] as int,
      estado: json['estado'] as String,
      fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
      fechaLlamado: convertirFecha(json['fecha_llamado'] as String?),
      fechaAtencion: convertirFecha(json['fecha_atencion'] as String?),
    );
  }

  /// Convierte una fecha del backend y conserva los valores nulos.
  static DateTime? convertirFecha(String? valor) {
    if (valor == null) {
      return null;
    }

    return DateTime.parse(valor);
  }
}
