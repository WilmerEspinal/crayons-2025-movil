class Cuota {
  final int id;
  final int idMatricula;
  final String matriculaPrecio;
  final int matriculaEstado;
  final String c1;
  final int c1Estado;
  final String c2;
  final int c2Estado;
  final String c3;
  final int c3Estado;
  final String c4;
  final int c4Estado;
  final String c5;
  final int c5Estado;
  final String c6;
  final int c6Estado;
  final String c7;
  final int c7Estado;
  final String c8;
  final int c8Estado;
  final String c9;
  final int c9Estado;
  final String c10;
  final int c10Estado;
  final String createdAt;
  final String updatedAt;

  Cuota({
    required this.id,
    required this.idMatricula,
    required this.matriculaPrecio,
    required this.matriculaEstado,
    required this.c1,
    required this.c1Estado,
    required this.c2,
    required this.c2Estado,
    required this.c3,
    required this.c3Estado,
    required this.c4,
    required this.c4Estado,
    required this.c5,
    required this.c5Estado,
    required this.c6,
    required this.c6Estado,
    required this.c7,
    required this.c7Estado,
    required this.c8,
    required this.c8Estado,
    required this.c9,
    required this.c9Estado,
    required this.c10,
    required this.c10Estado,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Cuota.fromJson(Map<String, dynamic> json) {
    return Cuota(
      id: json['id'],
      idMatricula: json['id_matricula'],
      matriculaPrecio: json['matricula_precio'],
      matriculaEstado: json['matricula_estado'],
      c1: json['c1'],
      c1Estado: json['c1_estado'],
      c2: json['c2'],
      c2Estado: json['c2_estado'],
      c3: json['c3'],
      c3Estado: json['c3_estado'],
      c4: json['c4'],
      c4Estado: json['c4_estado'],
      c5: json['c5'],
      c5Estado: json['c5_estado'],
      c6: json['c6'],
      c6Estado: json['c6_estado'],
      c7: json['c7'],
      c7Estado: json['c7_estado'],
      c8: json['c8'],
      c8Estado: json['c8_estado'],
      c9: json['c9'],
      c9Estado: json['c9_estado'],
      c10: json['c10'],
      c10Estado: json['c10_estado'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
} 