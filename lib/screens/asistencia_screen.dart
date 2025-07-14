import 'package:flutter/material.dart';
import '../models/asistencia.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AsistenciaScreen extends StatefulWidget {
  final String token;
  const AsistenciaScreen({super.key, required this.token});

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  late Future<List<Asistencia>> _futureAsistencias;

  @override
  void initState() {
    super.initState();
    _futureAsistencias = fetchAsistencias(widget.token);
  }

  Future<List<Asistencia>> fetchAsistencias(String token) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/api/alumno/mi-asistencia'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List asistenciasJson = data['data'];
      return asistenciasJson.map((json) => Asistencia.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar asistencias');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Asistencia'),
      ),
      body: FutureBuilder<List<Asistencia>>(
        future: _futureAsistencias,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error:  [31m${snapshot.error} [0m'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay asistencias'));
          }

          final asistencias = snapshot.data!;
          final asistenciasPresentes = asistencias.where((a) => a.presente).length;
          final asistenciasFaltas = asistencias.where((a) => !a.presente).length;
          final porcentaje = asistencias.isNotEmpty
              ? ((asistenciasPresentes / asistencias.length) * 100).toStringAsFixed(1)
              : '0.0';

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildEstadistica(
                      'Asistencias',
                      asistenciasPresentes.toString(),
                      Colors.green,
                    ),
                    _buildEstadistica(
                      'Faltas',
                      asistenciasFaltas.toString(),
                      Colors.red,
                    ),
                    _buildEstadistica(
                      'Porcentaje',
                      '$porcentaje%',
                      Colors.blue,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: asistencias.length,
                  itemBuilder: (context, index) {
                    final asistencia = asistencias[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: asistencia.presente
                              ? Colors.green
                              : Colors.red,
                          child: Icon(
                            asistencia.presente
                                ? Icons.check
                                : Icons.close,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(asistencia.curso),
                        subtitle: Text(
                          'Fecha: ${_formatDate(asistencia.fecha)}\nGrado: ${asistencia.grado}',
                        ),
                        trailing: asistencia.presente
                            ? null
                            : TextButton(
                                onPressed: () => _mostrarJustificacion(
                                  context,
                                  asistencia,
                                ),
                                child: const Text('Ver Justificación'),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEstadistica(
    String titulo,
    String valor,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _mostrarJustificacion(
    BuildContext context,
    Asistencia asistencia,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Justificación de Falta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Materia: ${asistencia.curso}'),
            const SizedBox(height: 8),
            Text('Fecha: ${_formatDate(asistencia.fecha)}'),
            const SizedBox(height: 16),
            const Text(
              'Justificación:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(asistencia.justificacion ?? 'Sin justificación'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
} 