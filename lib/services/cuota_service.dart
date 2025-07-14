import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cuota.dart';

class CuotaService {
  static const String baseUrl = 'http://10.0.2.2:3000/api/cuotas';

  Future<List<Cuota>> obtenerCuotas(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/mi-cuota'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == true) {
        final List cuotasJson = data['data'];
        return cuotasJson.map((e) => Cuota.fromJson(e)).toList();
      }
    }
    throw Exception('Error al obtener las cuotas');
  }
} 