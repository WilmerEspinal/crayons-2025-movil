import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// ignore: depend_on_referenced_packages
import 'package:url_launcher/url_launcher.dart';
import '../models/cuota.dart';
import '../services/cuota_service.dart';
import 'pago_webview_screen.dart';

class CuotasScreen extends StatefulWidget {
  final String token;
  const CuotasScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<CuotasScreen> createState() => _CuotasScreenState();
}

class _CuotasScreenState extends State<CuotasScreen> {
  late Future<List<Cuota>> _futureCuotas;

  @override
  void initState() {
    super.initState();
    _futureCuotas = CuotaService().obtenerCuotas(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis cuotas')),
      body: FutureBuilder<List<Cuota>>(
        future: _futureCuotas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay cuotas disponibles.'));
          }
          final cuota = snapshot.data!.first;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Card de Matrícula
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.blue[50],
                child: ListTile(
                  leading: Icon(Icons.school, color: Colors.blue[700], size: 18),
                  title: const Text('Matrícula', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Costo: S/ ${cuota.matriculaPrecio}'),
                  trailing: _estadoChip(cuota.matriculaEstado),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Cuotas mensuales', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...List.generate(10, (i) {
                final cuotaNum = i + 1;
                final monto = _cuotaValor(cuota, cuotaNum);
                final estado = _cuotaEstado(cuota, cuotaNum);
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          estado == 1 ? Icons.check_circle : Icons.attach_money,
                          color: estado == 1 ? Colors.green : Colors.blue,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text('Cuota $cuotaNum', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10)),
                        const SizedBox(width: 3),
                        Text('S/ $monto', style: const TextStyle(fontSize: 10, color: Colors.black87)),
                        const Spacer(),
                        _estadoChip(estado, fontSize: 8),
                        if (estado != 1) ...[
                          const SizedBox(width: 3),
                          SizedBox(
                            height: 22,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                minimumSize: const Size(0, 18),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                backgroundColor: Colors.blue[50],
                              ),
                              onPressed: () {
                                _mostrarDialogoPago(context, cuotaNum, monto);
                              },
                              child: const Text('Pagar', style: TextStyle(fontSize: 9)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  String _cuotaValor(Cuota cuota, int i) {
    switch (i) {
      case 1:
        return cuota.c1;
      case 2:
        return cuota.c2;
      case 3:
        return cuota.c3;
      case 4:
        return cuota.c4;
      case 5:
        return cuota.c5;
      case 6:
        return cuota.c6;
      case 7:
        return cuota.c7;
      case 8:
        return cuota.c8;
      case 9:
        return cuota.c9;
      case 10:
        return cuota.c10;
      default:
        return '';
    }
  }

  int _cuotaEstado(Cuota cuota, int i) {
    switch (i) {
      case 1:
        return cuota.c1Estado;
      case 2:
        return cuota.c2Estado;
      case 3:
        return cuota.c3Estado;
      case 4:
        return cuota.c4Estado;
      case 5:
        return cuota.c5Estado;
      case 6:
        return cuota.c6Estado;
      case 7:
        return cuota.c7Estado;
      case 8:
        return cuota.c8Estado;
      case 9:
        return cuota.c9Estado;
      case 10:
        return cuota.c10Estado;
      default:
        return 0;
    }
  }

  Widget _estadoChip(int estado, {double fontSize = 12}) {
    if (estado == 1) {
      return Chip(
        label: Text('Pagada', style: TextStyle(color: Colors.white, fontSize: fontSize)),
        backgroundColor: Colors.green,
        avatar: Icon(Icons.check_circle, color: Colors.white, size: fontSize + 7),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
      );
    } else {
      return Chip(
        label: Text('Pendiente', style: TextStyle(color: Colors.white, fontSize: fontSize)),
        backgroundColor: Colors.orange,
        avatar: Icon(Icons.hourglass_bottom, color: Colors.white, size: fontSize + 7),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
      );
    }
  }

  Future<void> _pagarCuota(int cuotaNum) async {
    final url = Uri.parse('http://10.0.2.2:3000/api/pago/mercadopago/cuota');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'anio': '2025',
        'tipo_cuota': cuotaNum.toString(),
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['init_point'] != null) {
        final initPoint = data['init_point'];
        if (await canLaunchUrl(Uri.parse(initPoint))) {
          await launchUrl(Uri.parse(initPoint), mode: LaunchMode.externalApplication);
        } else {
          _mostrarError('No se pudo abrir el navegador.');
        }
      } else {
        _mostrarError('No se pudo obtener el enlace de pago.');
      }
    } else {
      _mostrarError('Error al procesar el pago.');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  void _mostrarDialogoPago(BuildContext context, int cuotaNum, String monto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cuota: $cuotaNum'),
            const SizedBox(height: 8),
            Text('Monto: S/ $monto'),
            const SizedBox(height: 16),
            const Text(
              '¿Deseas proceder con el pago?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _pagarCuota(cuotaNum);
            },
            child: const Text('Confirmar Pago'),
          ),
        ],
      ),
    );
  }
}