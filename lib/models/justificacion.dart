class Justificacion {
  final int id;
  final String titulo;
  final String descripcion;
  final String tipoJustificacion;
  final String fechaFalta;
  final String idDocente;
  final String? urlPdf;
  final String estado;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Justificacion({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.tipoJustificacion,
    required this.fechaFalta,
    required this.idDocente,
    this.urlPdf,
    required this.estado,
    this.createdAt,
    this.updatedAt,
  });

  factory Justificacion.fromJson(Map<String, dynamic> json) {
    return Justificacion(
      id: json['id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'] ?? '',
      tipoJustificacion: json['tipo_justificacion'] ?? '',
      fechaFalta: json['fecha_falta'],
      idDocente: json['id_docente'].toString(),
      urlPdf: json['url_pdf'],
      estado: json['estado'] ?? 'pendiente',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'tipo_justificacion': tipoJustificacion,
      'fecha_falta': fechaFalta,
      'id_docente': idDocente,
      'url_pdf': urlPdf,
      'estado': estado,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
} 