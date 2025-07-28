import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class UserService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  Future<Map<String, dynamic>> obtenerPerfilUsuario(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('STATUS: ${response.statusCode}');
      print('BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? data,
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Error al obtener perfil',
        };
      }
    } catch (e) {
      print('ERROR EN OBTENER PERFIL: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  Future<int?> obtenerIdDocente(String token) async {
    try {
      final result = await obtenerPerfilUsuario(token);
      
      if (result['success']) {
        final userData = result['data'];
        // Intentar obtener el ID del docente de diferentes campos posibles
        final idDocente = userData['id_docente'] ?? 
                       
                         userData['user_id'] ?? 
                         userData['id'];
        
        if (idDocente != null) {
          return int.tryParse(idDocente.toString());
        }
      }
      
      return null;
    } catch (e) {
      print('ERROR AL OBTENER ID DOCENTE: $e');
      return null;
    }
  }
} 