import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class PantallaSoporte extends StatefulWidget {
  final String? orderId;
  const PantallaSoporte({super.key, this.orderId});

  @override
  State<PantallaSoporte> createState() => _PantallaSoporteState();
}

class _PantallaSoporteState extends State<PantallaSoporte> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  String _asuntoSeleccionado = 'Producto Defectuoso';
  String? _pedidoSeleccionadoId; // ID del pedido seleccionado
  File? _imagenAdjunta;
  bool _enviando = false;
  List<Map<String, dynamic>> _misPedidos = [];
  bool _cargandoPedidos = true;

  final List<String> _asuntos = [
    'Producto Defectuoso',
    'Problema de Envío',
    'Consulta General',
    'Devolución',
    'Otro'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.orderId != null) {
      _pedidoSeleccionadoId = widget.orderId;
    }
    _cargarPedidos();
  }

  Future<void> _cargarPedidos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('Pedidos')
            .where('userId', isEqualTo: user.uid)
            // .orderBy('fecha', descending: true) // Comentado para evitar error de índice
            .limit(50)
            .get();

        final pedidosCargados = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'fecha': (data['fecha'] as Timestamp).toDate(),
            'total': data['total'] ?? 0.0,
            'estado': data['estado'] ?? 'Desconocido',
          };
        }).toList();

        // Ordenar en memoria
        pedidosCargados.sort((a, b) =>
            (b['fecha'] as DateTime).compareTo(a['fecha'] as DateTime));

        setState(() {
          _misPedidos = pedidosCargados;

          // Verificar si el pedido pre-seleccionado existe en la lista
          if (_pedidoSeleccionadoId != null) {
            final existe =
                _misPedidos.any((p) => p['id'] == _pedidoSeleccionadoId);
            if (!existe) {
              _pedidoSeleccionadoId =
                  null; // Si no está en la lista (ej. más antiguo de 50), resetear
            }
          }

          _cargandoPedidos = false;
        });
      } catch (e) {
        debugPrint('Error cargando pedidos: $e');
        setState(() => _cargandoPedidos = false);
      }
    }
  }

  Future<void> _seleccionarImagen() async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Tomar foto'),
                onTap: () async {
                  Navigator.pop(context,
                      await picker.pickImage(source: ImageSource.camera));
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Elegir de galería'),
                onTap: () async {
                  Navigator.pop(context,
                      await picker.pickImage(source: ImageSource.gallery));
                },
              ),
            ],
          ),
        );
      },
    );

    if (image != null) {
      setState(() {
        _imagenAdjunta = File(image.path);
      });
    }
  }

  Future<void> _enviarTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      String? imageUrl;

      // 1. Subir imagen si existe
      if (_imagenAdjunta != null) {
        final String fileName =
            'support_images/${DateTime.now().millisecondsSinceEpoch}_${user.uid}.jpg';
        final Reference ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(_imagenAdjunta!);
        imageUrl = await ref.getDownloadURL();
      }

      // 2. Guardar ticket en Firestore
      await FirebaseFirestore.instance.collection('Soporte').add({
        'userId': user.uid,
        'userEmail': user.email,
        'asunto': _asuntoSeleccionado,
        'pedidoId': _pedidoSeleccionadoId, // Guardar ID del pedido
        'descripcion': _descripcionController.text.trim(),
        'imagenUrl': imageUrl,
        'fecha': FieldValue.serverTimestamp(),
        'estado': 'Pendiente', // Pendiente, En Proceso, Resuelto
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Ticket enviado correctamente'),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _enviando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar ticket: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Soporte Técnico'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Informativo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.headset_mic,
                        color: Theme.of(context).primaryColor, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¿Cómo podemos ayudarte?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Envíanos un ticket y te responderemos pronto.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Campo Asunto
              Text(
                'Asunto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _asuntoSeleccionado,
                    isExpanded: true,
                    items: _asuntos.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _asuntoSeleccionado = newValue!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Campo Selección de Pedido (Opcional)
              Text(
                'Pedido Relacionado (Opcional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              _cargandoPedidos
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _pedidoSeleccionadoId,
                          hint: const Text('Selecciona un pedido...'),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Ninguno / No aplica'),
                            ),
                            ..._misPedidos.map((pedido) {
                              final fecha = DateFormat('dd/MM/yyyy')
                                  .format(pedido['fecha']);
                              return DropdownMenuItem<String>(
                                value: pedido['id'],
                                child: Text(
                                  'Pedido #${pedido['id'].toString().substring(0, 6)}... - $fecha - \$${pedido['total']}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                          ],
                          onChanged: (newValue) {
                            setState(() {
                              _pedidoSeleccionadoId = newValue;
                            });
                          },
                        ),
                      ),
                    ),
              const SizedBox(height: 20),

              // Campo Descripción
              Text(
                'Descripción del Problema',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descripcionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Describe tu problema detalladamente...',
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Adjuntar Imagen
              Text(
                'Adjuntar Evidencia (Opcional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),

              if (_imagenAdjunta != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _imagenAdjunta!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: () => setState(() => _imagenAdjunta = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                )
              else
                InkWell(
                  onTap: _seleccionarImagen,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                        style: BorderStyle.solid,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined,
                            size: 32, color: Theme.of(context).primaryColor),
                        const SizedBox(height: 8),
                        Text(
                          'Tocar para adjuntar foto',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // Botón Enviar
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _enviando ? null : _enviarTicket,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: _enviando
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Enviar Ticket',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
