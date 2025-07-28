class Asistencia {
  final int id;
  final String curso;
  final String grado;
  final DateTime fecha;
  final bool presente;
  final String? justificacion;
  final int? idDocenteCurso;
  final int? idDocente;
  final String? nombreDocente;
  final String? apPDocente;
  final String? apMDocente;
  final String? nombreCompletoDocente;

  Asistencia({
    required this.id,
    required this.curso,
    required this.grado,
    required this.fecha,
    required this.presente,
    this.justificacion,
    this.idDocenteCurso,
    this.idDocente,
    this.nombreDocente,
    this.apPDocente,
    this.apMDocente,
    this.nombreCompletoDocente,
  });

  factory Asistencia.fromJson(Map<String, dynamic> json) {
    return Asistencia(
      id: json['id'],
      curso: json['curso'] ?? 'Curso', // Fallback para faltas-justificar
      grado: json['grado'] ?? 'Grado', // Fallback para faltas-justificar
      fecha: DateTime.parse(json['fecha']),
      presente: json['asistio'] == 1,
      justificacion: (json['observacion'] as String?)?.isEmpty == true ? null : json['observacion'],
      idDocenteCurso: json['id_docente_curso'],
      idDocente: json['id_docente'],
      nombreDocente: json['nombre_docente'],
      apPDocente: json['ap_p_docente'],
      apMDocente: json['ap_m_docente'],
      nombreCompletoDocente: json['nombre_completo_docente'],
    );
  }
} 