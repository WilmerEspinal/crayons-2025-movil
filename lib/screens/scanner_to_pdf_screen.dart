import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import '../models/asistencia.dart';
import '../services/justificacion_service.dart';

class ScannerToPdfScreen extends StatefulWidget {
  final dynamic asistencia;
  final String token;
  const ScannerToPdfScreen({Key? key, this.asistencia, required this.token}) : super(key: key);

  @override
  State<ScannerToPdfScreen> createState() => _ScannerToPdfScreenState();
}

class _ScannerToPdfScreenState extends State<ScannerToPdfScreen> {
  final ImagePicker _picker = ImagePicker();
  final JustificacionService _justificacionService = JustificacionService();
  List<XFile> _images = [];
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _pdfPath;
  String _pdfSize = '';
  int? _idDocente;
  
  // Controllers para los campos del formulario
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _fechaFaltaController = TextEditingController();
  String _tipoJustificacion = 'medica';
  String _idDocenteString = '1'; // Valor por defecto
  String _nombreDocente = ''; // Nombre del docente

  @override
  void initState() {
    super.initState();
    _obtenerIdDocente();
  }

  Future<void> _obtenerIdDocente() async {
    try {
      if (widget.asistencia != null) {
        final asistencia = widget.asistencia;
        
        // Usar el id_docente_curso directamente como id_docente
        // Ya que en tu estructura, el id_docente_curso es el identificador del docente
        final idDocente = asistencia.idDocenteCurso;
        
        if (idDocente != null) {
          // Debug: imprimir todos los campos del docente
          print('=== DEBUG DOCENTE ===');
          print('nombre_docente: ${asistencia.nombreDocente}');
          print('ap_p_docente: ${asistencia.apPDocente}');
          print('ap_m_docente: ${asistencia.apMDocente}');
          print('nombre_completo_docente: ${asistencia.nombreCompletoDocente}');
          print('=====================');
          
          setState(() {
            _idDocenteString = 'ID: $idDocente';
            _idDocente = idDocente; // Guardar el ID real
            // Construir el nombre completo si no viene
            String nombreCompleto = asistencia.nombreCompletoDocente ?? '';
            if (nombreCompleto.isEmpty && asistencia.nombreDocente != null) {
              nombreCompleto = '${asistencia.nombreDocente} ${asistencia.apPDocente ?? ''} ${asistencia.apMDocente ?? ''}'.trim();
            }
            _nombreDocente = nombreCompleto.isNotEmpty ? nombreCompleto : 'Docente';
          });
          print('ID Docente obtenido: $idDocente');
          print('Nombre del docente: ${asistencia.nombreCompletoDocente}');
          print('Nombre guardado en UI: $_nombreDocente');
        } else {
          setState(() {
            _idDocenteString = 'Sin ID docente curso';
          });
          print('No hay id_docente_curso disponible');
        }
      } else {
        setState(() {
          _idDocenteString = 'Sin asistencia';
        });
        print('No hay asistencia disponible');
      }
    } catch (e) {
      setState(() {
        _idDocenteString = 'Error: $e';
      });
      print('Error al obtener ID del docente: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _images.addAll(picked);
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        _images.add(picked);
      });
    }
  }

  Future<void> _generatePdf() async {
    setState(() { _isLoading = true; });
    
    try {
    final pdf = pw.Document();
      
      // Primera página con información de la justificación
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Justificación de Falta', style: pw.TextStyle(fontSize: 20)),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Título: ${_tituloController.text}'),
              pw.SizedBox(height: 10),
              pw.Text('Descripción: ${_descripcionController.text}'),
              pw.SizedBox(height: 10),
              pw.Text('Fecha de falta: ${_fechaFaltaController.text}'),
              pw.SizedBox(height: 10),
              pw.Text('Tipo: ${_getTipoJustificacion(_tipoJustificacion)}'),
              pw.SizedBox(height: 20),
              pw.Text('Documento generado el: ${DateTime.now().toString()}'),
            ],
          ),
        ),
      );
      
                      // Agregar páginas con las imágenes escaneadas optimizadas
        for (int i = 0; i < _images.length; i++) {
          final img = _images[i];
          
          try {
            print('Procesando imagen ${i + 1}: ${img.path}');
            
            // Optimizar la imagen para reducir tamaño
            final optimizedBytes = await _optimizeImage(img.path);
            
            if (optimizedBytes.isNotEmpty) {
              final pwImage = pw.MemoryImage(optimizedBytes);
              
              pdf.addPage(
                pw.Page(
                  pageFormat: PdfPageFormat.a4,
                  build: (pw.Context context) => pw.Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: pw.Center(
                      child: pw.Image(
                        pwImage,
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              );
              
              print('Imagen ${i + 1} optimizada y agregada al PDF');
            } else {
              print('Imagen ${i + 1} está vacía, saltando...');
            }
          } catch (e) {
            print('Error al procesar imagen ${i + 1}: $e');
          }
        }
      
    final output = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File("${output.path}/justificacion_$timestamp.pdf");
      
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      
      // Verificar que el archivo se creó correctamente
      if (!await file.exists()) {
        throw Exception('No se pudo crear el archivo PDF');
      }
      
      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('El archivo PDF está vacío');
      }
      
    setState(() {
      _pdfPath = file.path;
      _isLoading = false;
    });
      
      print('PDF generado exitosamente: ${file.path}');
      print('Tamaño del archivo: ${fileSize} bytes');
      
      // Calcular tamaño en KB para mostrar al usuario
      final sizeInKB = (fileSize / 1024).toStringAsFixed(1);
      print('Tamaño del archivo: ${sizeInKB} KB');
      
      setState(() {
        _pdfPath = file.path;
        _pdfSize = '${sizeInKB} KB';
        _isLoading = false;
      });
      
      // Abrir el archivo para verificación
    OpenFile.open(file.path);
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('ERROR AL GENERAR PDF: $e');
    }
  }

  String _getTipoJustificacion(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'medica':
        return 'Médica';
      case 'personal':
        return 'Personal';
      case 'academica':
        return 'Académica';
      default:
        return tipo;
    }
  }

  /// Optimiza una imagen para mejorar la calidad del PDF
  Future<Uint8List> _optimizeImage(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      
      // Decodificar la imagen
      final image = img.decodeImage(bytes);
      if (image == null) {
        print('No se pudo decodificar la imagen: $imagePath');
        return bytes;
      }

      // Obtener dimensiones originales
      final originalWidth = image.width;
      final originalHeight = image.height;
      
      print('Imagen original: ${originalWidth}x${originalHeight}');

      // Calcular nuevas dimensiones (máximo 800px de ancho para PDF - más pequeño)
      int newWidth = originalWidth;
      int newHeight = originalHeight;
      
      if (originalWidth > 800) {
        newWidth = 800;
        newHeight = (originalHeight * 800 / originalWidth).round();
      }

      // Redimensionar si es necesario
      img.Image resizedImage;
      if (newWidth != originalWidth || newHeight != originalHeight) {
        resizedImage = img.copyResize(
          image,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
        print('Imagen redimensionada a: ${newWidth}x${newHeight}');
      } else {
        resizedImage = image;
      }

      // Mejorar la calidad de la imagen (contraste y brillo)
      final enhancedImage = img.adjustColor(
        resizedImage,
        contrast: 1.1,
        brightness: 1.05,
      );
      
      // Convertir a JPEG con calidad optimizada para PDF (más compresión)
      final optimizedBytes = img.encodeJpg(enhancedImage, quality: 70);
      
      print('Imagen optimizada: ${optimizedBytes.length} bytes');
      return Uint8List.fromList(optimizedBytes);
      
    } catch (e) {
      print('Error al optimizar imagen: $e');
      // Si falla la optimización, devolver la imagen original
      final file = File(imagePath);
      return await file.readAsBytes();
    }
  }

  Future<void> _sendJustification() async {
    if (_pdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debes generar el PDF'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_tituloController.text.isEmpty || _descripcionController.text.isEmpty || _fechaFaltaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes completar todos los campos'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final pdfFile = File(_pdfPath!);
              final result = await _justificacionService.crearJustificacion(
          token: widget.token,
          titulo: _tituloController.text,
          descripcion: _descripcionController.text,
          tipoJustificacion: _tipoJustificacion,
          fechaFalta: _fechaFaltaController.text,
          idAsistencia: widget.asistencia.id.toString(), // Enviar el ID de la asistencia
          pdfFile: pdfFile,
          onProgress: (progress) {
            setState(() {
              _uploadProgress = progress;
            });
          },
        );

      setState(() {
        _isUploading = false;
      });

      if (result['success']) {
        // Mostrar el ID del docente que se usó
        final responseData = result['data'];
        final idDocenteUsado = responseData?['id_docente'];
        
        String mensaje = result['message'] ?? 'Justificación enviada exitosamente';
        if (idDocenteUsado != null) {
          mensaje += '\nID Docente usado: $idDocenteUsado';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
        
        // Actualizar el ID mostrado en la UI
        if (idDocenteUsado != null) {
          setState(() {
            _idDocenteString = 'Usado: $idDocenteUsado';
          });
        }
        
        // Mostrar diálogo con detalles
        _mostrarDetallesEnvio(responseData);
        
        // Limpiar el formulario
        _tituloController.clear();
        _descripcionController.clear();
        _fechaFaltaController.clear();
        setState(() {
          _images.clear();
          _pdfPath = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al enviar la justificación'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
    );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Justificar Falta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Botones para capturar imágenes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Cámara'),
                  onPressed: _pickFromCamera,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galería'),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Vista previa de imágenes
            if (_images.isNotEmpty) ...[
              const Text('Imágenes seleccionadas:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.file(
                            File(_images[index].path),
                            width: 150,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Formulario de datos de la justificación
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Datos de la justificación:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    
                    // Información del docente y curso
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person, color: Colors.blue[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Docente:',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    if (_nombreDocente.isNotEmpty && _nombreDocente != 'Docente')
                                      Text(
                                        _nombreDocente,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      )
                                    else if (widget.asistencia.nombreDocente != null)
                                      Text(
                                        '${widget.asistencia.nombreDocente} ${widget.asistencia.apPDocente ?? ''} ${widget.asistencia.apMDocente ?? ''}'.trim(),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      )
                                    else
                                      Text(
                                        'Docente no disponible',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red[600]),
                                      ),
                                    Text(
                                      'ID Asistencia: ${widget.asistencia.id}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                    Text(
                                      _idDocente != null ? '(obtenido del curso)' : '(por defecto)',
                                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (widget.asistencia != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.school, color: Colors.blue[700], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Curso y Fecha:',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      Text(
                                        widget.asistencia.curso,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Fecha: ${_formatDate(widget.asistencia.fecha.toString())}',
                                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue[700], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Estado de Asistencia:',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: widget.asistencia.presente ? Colors.green[100] : Colors.red[100],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          widget.asistencia.presente ? 'PRESENTE' : 'AUSENTE',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: widget.asistencia.presente ? Colors.green[800] : Colors.red[800],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            // Información técnica (para debugging)
                            if (widget.asistencia.idDocenteCurso != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.code, color: Colors.grey[600], size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Información Técnica:',
                                          style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ID Docente Curso: ${widget.asistencia.idDocenteCurso}',
                                      style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                                    ),
                                    Text(
                                      'ID Asistencia: ${widget.asistencia.id}',
                                      style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                                    ),
                                    Text(
                                      'ID Docente (backend): ${widget.asistencia.idDocenteCurso}',
                                      style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    
                    // Botón de debug temporal
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Debug - Datos del Docente'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID Asistencia: ${widget.asistencia.id}'),
                                Text('nombre_docente: ${widget.asistencia.nombreDocente ?? 'null'}'),
                                Text('ap_p_docente: ${widget.asistencia.apPDocente ?? 'null'}'),
                                Text('ap_m_docente: ${widget.asistencia.apMDocente ?? 'null'}'),
                                Text('nombre_completo_docente: ${widget.asistencia.nombreCompletoDocente ?? 'null'}'),
                                Text('id_docente_curso: ${widget.asistencia.idDocenteCurso ?? 'null'}'),
                                Text('_nombreDocente: $_nombreDocente'),
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
                      },
                      child: const Text('Debug Docente'),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Título
                    TextField(
                      controller: _tituloController,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        hintText: 'Ej: Cita médica - Fiebre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Descripción
                    TextField(
                      controller: _descripcionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        hintText: 'Explica el motivo de la falta',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Tipo de justificación
                    DropdownButtonFormField<String>(
                      value: _tipoJustificacion,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de justificación',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'medica', child: Text('Médica')),
                        DropdownMenuItem(value: 'personal', child: Text('Personal')),
                        DropdownMenuItem(value: 'academica', child: Text('Académica')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _tipoJustificacion = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Fecha de falta
                    TextField(
                      controller: _fechaFaltaController,
                      decoration: const InputDecoration(
                        labelText: 'Fecha de falta',
                        hintText: 'YYYY-MM-DD',
                        border: OutlineInputBorder(),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          _fechaFaltaController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            
            // Botones de acción
            if (_isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Optimizando imágenes y generando PDF...', textAlign: TextAlign.center),
            ]
            else if (_images.isNotEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: Text('Generar PDF con ${_images.length} imagen${_images.length == 1 ? '' : 'es'}'),
                onPressed: _generatePdf,
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'Selecciona al menos una imagen para generar el PDF',
                  style: TextStyle(color: Colors.orange),
                  textAlign: TextAlign.center,
                ),
              ),
            
            if (_pdfPath != null && !_isLoading) ...[
              if (_isUploading) ...[
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Archivo: $_pdfSize', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        Text('${(_uploadProgress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _uploadProgress < 0.3 ? 'Preparando archivo...' :
                      _uploadProgress < 0.6 ? 'Subiendo al servidor...' :
                      _uploadProgress < 0.9 ? 'Procesando en el servidor...' : 'Finalizando...',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Enviar Justificación'),
                onPressed: _sendJustification,
              ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _pdfSize,
                        style: TextStyle(color: Colors.green[800], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _mostrarDetallesEnvio(Map<String, dynamic>? responseData) {
    if (responseData == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Justificación Enviada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID Justificación: ${responseData['id'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Título: ${responseData['titulo'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('ID Asistencia: ${responseData['id_asistencia'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('ID Docente (backend): ${responseData['id_docente'] ?? 'N/A'}'),
            if (_nombreDocente.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Docente: $_nombreDocente', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 8),
            Text('Estado: ${responseData['estado'] ?? 'N/A'}'),
            if (responseData['url_pdf'] != null) ...[
              const SizedBox(height: 8),
              const Text('PDF:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                responseData['url_pdf'],
                style: const TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ],
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