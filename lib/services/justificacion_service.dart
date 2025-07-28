import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/justificacion.dart';

class JustificacionService {
  static const String baseUrl = 'http://10.0.2.2:3000/api/justificaciones';

                Future<Map<String, dynamic>> crearJustificacion({
                required String token,
                required String titulo,
                required String descripcion,
                required String tipoJustificacion,
                required String fechaFalta,
                required String idAsistencia,
                required File pdfFile,
                Function(double)? onProgress,
              }) async {
    try {
      // Verificar que el archivo existe y no está vacío
      if (!await pdfFile.exists()) {
        return {
          'success': false,
          'message': 'El archivo PDF no existe',
        };
      }

      final fileSize = await pdfFile.length();
      if (fileSize == 0) {
        return {
          'success': false,
          'message': 'El archivo PDF está vacío',
        };
      }

      print('Enviando archivo PDF: ${pdfFile.path}');
      print('Tamaño del archivo: $fileSize bytes');

      // Crear la petición multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/crear'),
      );

      // Agregar headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'multipart/form-data';

      // Agregar campos de texto
                        request.fields['titulo'] = titulo;
                  request.fields['descripcion'] = descripcion;
                  request.fields['tipo_justificacion'] = tipoJustificacion;
                  request.fields['fecha_falta'] = fechaFalta;
                  request.fields['id_asistencia'] = idAsistencia;

                        print('Campos enviados:');
                  print('- titulo: $titulo');
                  print('- descripcion: $descripcion');
                  print('- tipo_justificacion: $tipoJustificacion');
                  print('- fecha_falta: $fechaFalta');
                  print('- id_asistencia: $idAsistencia');

      // Agregar el archivo PDF
      final multipartFile = await http.MultipartFile.fromPath(
        'pdf',
        pdfFile.path,
        filename: 'justificacion.pdf',
        contentType: MediaType('application', 'pdf'),
      );
      
      request.files.add(multipartFile);

      print('Enviando petición a: $baseUrl/crear');
      
      // Enviar la petición con timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: La subida tardó demasiado');
        },
      );
      
      // Simular progreso de subida
      onProgress?.call(0.2);
      await Future.delayed(const Duration(milliseconds: 100));
      
      onProgress?.call(0.5);
      await Future.delayed(const Duration(milliseconds: 100));
      
      onProgress?.call(0.8);
      await Future.delayed(const Duration(milliseconds: 100));
      
      final response = await http.Response.fromStream(streamedResponse);
      
      // Reportar progreso final
      onProgress?.call(1.0);

      print('STATUS: ${response.statusCode}');
      print('HEADERS: ${response.headers}');
      print('BODY: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);
          final responseData = data['data'];
          
          // Mostrar el id_docente que se usó
          if (responseData != null && responseData['id_docente'] != null) {
            print('ID Docente usado en la justificación: ${responseData['id_docente']}');
          }
          
          return {
            'success': true,
            'data': responseData,
            'message': data['message'] ?? 'Justificación creada exitosamente',
          };
        } catch (e) {
          print('ERROR AL PARSEAR JSON: $e');
          return {
            'success': false,
            'message': 'Respuesta inválida del servidor',
          };
        }
      } else {
        try {
          final data = jsonDecode(response.body);
          return {
            'success': false,
            'message': data['message'] ?? 'Error al crear la justificación',
          };
        } catch (e) {
          print('ERROR AL PARSEAR JSON DE ERROR: $e');
          return {
            'success': false,
            'message': 'Error del servidor: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      print('ERROR EN CREAR JUSTIFICACIÓN: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  Future<Map<String, dynamic>> obtenerJustificaciones(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mis-justificaciones'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> justificacionesJson = data['data'];
        final justificaciones = justificacionesJson
            .map((json) => Justificacion.fromJson(json))
            .toList();
        return {
          'success': true,
          'data': justificaciones,
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Error al obtener justificaciones',
        };
      }
    } catch (e) {
      print('ERROR EN OBTENER JUSTIFICACIONES: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
} 