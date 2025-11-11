import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import para LatLng
import 'seleccionar_ubicacion.dart'; // Importa la nueva pantalla

class PantallaDirecciones extends StatefulWidget {
  const PantallaDirecciones({super.key});

  @override
  State<PantallaDirecciones> createState() => _PantallaDireccionesState();
}

class _PantallaDireccionesState extends State<PantallaDirecciones> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  User? _usuario;

  bool _mostrandoFormulario = false;
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _referenciaController = TextEditingController();
  bool _cargandoFormulario = false;
  bool _obteniendoUbicacion = false; // Para la detección automática

  // --- ¡NUEVO! Almacena las coordenadas seleccionadas ---
  LatLng? _ubicacionSeleccionadaMapa;
  // ---------------------------------------------------

  @override
  void initState() {
    super.initState();
    _usuario = _auth.currentUser;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    _referenciaController.dispose();
    super.dispose();
  }

  // --- Función para obtener la ubicación actual ---
  Future<void> _obtenerUbicacionActual() async {
    setState(() {
      _obteniendoUbicacion = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Servicio de ubicación deshabilitado.'), backgroundColor: Colors.orange),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Permiso de ubicación denegado.'), backgroundColor: Colors.orange),
             );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Permiso denegado permanentemente. Actívalo en ajustes.'), backgroundColor: Colors.orange),
           );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String direccionCompleta = place.street ?? place.name ?? '';
        String ciudad = place.locality ?? place.administrativeArea ?? '';

        setState(() {
          _direccionController.text = direccionCompleta;
          _ciudadController.text = ciudad;
          // --- ¡ACTUALIZACIÓN! Guardar las coordenadas ---
          _ubicacionSeleccionadaMapa = LatLng(position.latitude, position.longitude);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ubicación detectada: ${place.locality ?? place.administrativeArea}')),
          );
        }
      } else {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se pudo obtener la dirección.'), backgroundColor: Colors.orange),
            );
         }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener ubicación: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _obteniendoUbicacion = false;
        });
      }
    }
  }
  // -----------------------------------------------


  // --- Función para abrir la pantalla de selección ---
  Future<void> _abrirSeleccionarUbicacion() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SeleccionarUbicacionScreen()),
    );

    if (resultado != null && resultado is Map<String, dynamic>) {
      String direccionCompleta = resultado['direccion'] ?? '';

      List<String> partes = direccionCompleta.split(', ');
      String direccion = partes.isNotEmpty ? partes[0] : '';
      String ciudad = partes.length > 1 ? partes[1] : '';

      setState(() {
        _direccionController.text = direccion;
        _ciudadController.text = ciudad;
        // --- ¡ACTUALIZACIÓN! Guardar las coordenadas ---
        _ubicacionSeleccionadaMapa = resultado['latLng'];
      });
    }
  }
  // -----------------------------------------------------


  // --- Lógica de la Base de Datos ---
  Future<void> _guardarDireccion() async {
    if (!_formKey.currentState!.validate()) return;
    if (_usuario == null) return;

    setState(() { _cargandoFormulario = true; });

    try {
      await _firestore
          .collection('Usuarios')
          .doc(_usuario!.uid)
          .collection('Direcciones')
          .add({
        'nombre': _nombreController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'ciudad': _ciudadController.text.trim(),
        'referencia': _referenciaController.text.trim(),
        'creadoEn': FieldValue.serverTimestamp(),
        // --- ¡NUEVO! Guardar el GeoPoint en Firestore ---
        'ubicacion': _ubicacionSeleccionadaMapa != null
            ? GeoPoint(_ubicacionSeleccionadaMapa!.latitude, _ubicacionSeleccionadaMapa!.longitude)
            : null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dirección guardada'), backgroundColor: Colors.green),
        );
        _formKey.currentState?.reset();
        _nombreController.clear();
        _direccionController.clear();
        _ciudadController.clear();
        _referenciaController.clear();
        setState(() { 
          _mostrandoFormulario = false; 
          _ubicacionSeleccionadaMapa = null; // Limpiar al guardar
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _cargandoFormulario = false; });
      }
    }
  }

  Future<void> _eliminarDireccion(String docId) async {
    if (_usuario == null) return;

    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Dirección'),
        content: const Text('¿Estás seguro de que quieres eliminar esta dirección?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmacion == true) {
      try {
        await _firestore
            .collection('Usuarios')
            .doc(_usuario!.uid)
            .collection('Direcciones')
            .doc(docId)
            .delete();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_usuario == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mis Direcciones')),
        body: const Center(child: Text('Debes iniciar sesión.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_mostrandoFormulario ? 'Añadir Nueva Dirección' : 'Mis Direcciones'),
        leading: _mostrandoFormulario
            ? IconButton(
                icon: const Icon(Icons.close),
                // --- ¡ACTUALIZACIÓN! Limpiar coords al cerrar ---
                onPressed: () => setState(() { 
                  _mostrandoFormulario = false; 
                  _ubicacionSeleccionadaMapa = null; 
                }),
              )
            : null,
      ),
      body: _mostrandoFormulario
          ? _buildFormulario()
          : _buildListaStream(),
      floatingActionButton: _mostrandoFormulario
          ? null
          : FloatingActionButton(
              onPressed: () {
                setState(() { _mostrandoFormulario = true; });
              },
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildListaStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('Usuarios')
          .doc(_usuario!.uid)
          .collection('Direcciones')
          .orderBy('creadoEn', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final direcciones = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: direcciones.length,
          itemBuilder: (context, index) {
            final doc = direcciones[index];
            final data = doc.data() as Map<String, dynamic>;

            final nombre = data['nombre'] ?? 'Sin nombre';
            final direccion = data['direccion'] ?? 'Sin dirección';
            final ciudad = data['ciudad'] ?? 'Sin ciudad';
            // --- ¡NUEVO! Verificar si tiene ubicación guardada ---
            final bool tieneUbicacion = data.containsKey('ubicacion') && data['ubicacion'] != null;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(
                    nombre.toLowerCase() == 'casa' ? Icons.home :
                    nombre.toLowerCase() == 'oficina' ? Icons.work :
                    Icons.location_on,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('$direccion, $ciudad'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- ¡NUEVO! Icono visual si la ubicación es válida ---
                    Icon(
                      tieneUbicacion ? Icons.check_circle_outline : Icons.error_outline,
                      color: tieneUbicacion ? Colors.green : Colors.grey[400],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                      onPressed: () => _eliminarDireccion(doc.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFormulario() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la dirección',
                hintText: 'Ej. "Casa", "Oficina"',
                prefixIcon: Icon(Icons.label_outline),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Dale un nombre' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _direccionController,
              decoration: InputDecoration(
                labelText: 'Dirección (Calle y Número)',
                prefixIcon: const Icon(Icons.signpost_outlined),
                suffixIcon: _obteniendoUbicacion
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row( // Row para múltiples botones
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.my_location),
                            onPressed: _obtenerUbicacionActual, // Botón de detección automática
                          ),
                          IconButton( // Botón de selección en mapa
                            icon: const Icon(Icons.map),
                            onPressed: _abrirSeleccionarUbicacion,
                          ),
                        ],
                      ),
                border: const OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa tu dirección' : null,
              readOnly: _obteniendoUbicacion, // Bloquear mientras se detecta
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ciudadController,
              decoration: const InputDecoration(
                labelText: 'Ciudad',
                prefixIcon: Icon(Icons.location_city_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa tu ciudad' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _referenciaController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Referencia (Opcional)',
                hintText: 'Ej. "Puerta roja, frente al parque"',
                prefixIcon: Icon(Icons.maps_home_work_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _cargandoFormulario ? null : _guardarDireccion,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _cargandoFormulario
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                  : const Text('Guardar Dirección'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.maps_home_work_outlined, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              'No tienes direcciones',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Añade una nueva dirección de entrega para tus pedidos.',
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Añadir mi primera dirección'),
              onPressed: () {
                setState(() { _mostrandoFormulario = true; });
              },
            ),
          ],
        ),
      ),
    );
  }
}