import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:3000/api/auth';

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );
      print('STATUS: [32m${response.statusCode}[0m');
      print('BODY: [36m${response.body}[0m');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else if (data['change_password_required'] == true) {
        return {
          'success': false,
          'change_password_required': true,
          'message': data['message'] ?? 'Debes cambiar tu contraseña'
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Credenciales incorrectas'};
      }
    } catch (e) {
      print('ERROR EN LOGIN: $e');
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String username,
    required String email,
    required String password,
    required String newPassword,
    required String repeatPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/change-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'newPassword': newPassword,
        'repeatPassword': repeatPassword,
      }),
    );
    if (response.statusCode == 200) {
      return {'success': true};
    } else {
      final data = jsonDecode(response.body);
      return {'success': false, 'message': data['message'] ?? 'Error al cambiar la contraseña'};
    }
  }
} 