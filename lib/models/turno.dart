class Turno {
  final int id;
  final String estado;
  final DateTime fechaCreacion;
  final DateTime? fechaLlamado;
  final DateTime? fechaAtencion;

  const Turno({
    required this.id,
    required this.estado,
    required this.fechaCreacion,
    this.fechaLlamado,
    this.fechaAtencion,
  });

  factory Turno.fromJson(Map<String, dynamic> json) {
    return Turno(
      id: json['id'] as int,
      estado: json['estado'] as String,
      fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
      fechaLlamado: convertirFecha(json['fecha_llamado'] as String?),
      fechaAtencion: convertirFecha(json['fecha_atencion'] as String?),
    );
  }

  static DateTime? convertirFecha(String? valor) {
    if (valor == null) {
      return null;
    }

    return DateTime.parse(valor);
  }
}
