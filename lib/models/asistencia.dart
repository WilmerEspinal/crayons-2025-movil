class Asistencia {
  final int id;
  final String curso;
  final String grado;
  final DateTime fecha;
  final bool presente;
  final String? justificacion;

  Asistencia({
    required this.id,
    required this.curso,
    required this.grado,
    required this.fecha,
    required this.presente,
    this.justificacion,
  });

  factory Asistencia.fromJson(Map<String, dynamic> json) {
    return Asistencia(
      id: json['id'],
      curso: json['curso'] ?? '',
      grado: json['grado'] ?? '',
      fecha: DateTime.parse(json['fecha']),
      presente: json['asistio'] == 1,
      justificacion: (json['observacion'] as String?)?.isEmpty == true ? null : json['observacion'],
    );
  }
} 