import 'package:flutter/material.dart';
import '../models/justificacion.dart';
import '../services/justificacion_service.dart';
import 'package:url_launcher/url_launcher.dart';

class JustificacionesScreen extends StatefulWidget {
  final String token;
  const JustificacionesScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<JustificacionesScreen> createState() => _JustificacionesScreenState();
}

class _JustificacionesScreenState extends State<JustificacionesScreen> {
  late Future<Map<String, dynamic>> _futureJustificaciones;
  final JustificacionService _justificacionService = JustificacionService();

  @override
  void initState() {
    super.initState();
    _futureJustificaciones = _justificacionService.obtenerJustificaciones(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Justificaciones')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureJustificaciones,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || !snapshot.data!['success']) {
            return Center(child: Text(snapshot.data?['message'] ?? 'Error al cargar justificaciones'));
          }

          final List<Justificacion> justificaciones = snapshot.data!['data'];
          
          if (justificaciones.isEmpty) {
            return const Center(child: Text('No hay justificaciones enviadas'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: justificaciones.length,
            itemBuilder: (context, index) {
              final justificacion = justificaciones[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getEstadoColor(justificacion.estado),
                    child: Icon(_getEstadoIcon(justificacion.estado), color: Colors.white),
                  ),
                  title: Text(justificacion.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fecha: ${_formatDate(justificacion.fechaFalta)}'),
                      Text('Estado: ${_getEstadoText(justificacion.estado)}'),
                      if (justificacion.urlPdf != null)
                        TextButton.icon(
                          icon: const Icon(Icons.picture_as_pdf, size: 16),
                          label: const Text('Ver PDF'),
                          onPressed: () => _abrirPdf(justificacion.urlPdf!),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'aprobada': return Colors.green;
      case 'rechazada': return Colors.red;
      default: return Colors.orange;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'aprobada': return Icons.check_circle;
      case 'rechazada': return Icons.cancel;
      default: return Icons.hourglass_bottom;
    }
  }

  String _getEstadoText(String estado) {
    switch (estado.toLowerCase()) {
      case 'aprobada': return 'Aprobada';
      case 'rechazada': return 'Rechazada';
      default: return 'Pendiente';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _abrirPdf(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el PDF')),
      );
    }
  }
} 