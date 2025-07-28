import 'dart:convert';
import 'package:http/http.dart' as http;

class DocenteService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  Future<int?> obtenerIdDocenteDesdeCurso(String token, int idDocenteCurso) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/docente-curso/$idDocenteCurso'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('STATUS: ${response.statusCode}');
      print('BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final docenteCurso = data['data'] ?? data;
        
        // Obtener el id_docente desde docente_curso
        final idDocente = docenteCurso['id_docente'];
        
        if (idDocente != null) {
          print('ID Docente obtenido desde docente_curso: $idDocente');
          return int.tryParse(idDocente.toString());
        }
      }
      
      return null;
    } catch (e) {
      print('ERROR AL OBTENER ID DOCENTE DESDE CURSO: $e');
      return null;
    }
  }
} 