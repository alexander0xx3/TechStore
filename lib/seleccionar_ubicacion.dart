import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class SeleccionarUbicacionScreen extends StatefulWidget {
  const SeleccionarUbicacionScreen({super.key});

  @override
  State<SeleccionarUbicacionScreen> createState() => _SeleccionarUbicacionScreenState();
}

class _SeleccionarUbicacionScreenState extends State<SeleccionarUbicacionScreen> {
  GoogleMapController? _mapController;
  Position? _ubicacionActual;
  LatLng? _ubicacionSeleccionada;
  String _direccionSeleccionada = 'Toca en el mapa para seleccionar una ubicación';

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionInicial();
  }

  void _obtenerUbicacionInicial() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Manejar error de servicio deshabilitado
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Manejar error de permiso denegado
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Manejar error de permiso denegado permanentemente
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _ubicacionActual = position;
      _ubicacionSeleccionada = LatLng(position.latitude, position.longitude);
    });

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15.0,
          ),
        ),
      );
    }

    _actualizarDireccion(LatLng(position.latitude, position.longitude));
  }

  void _actualizarDireccion(LatLng latLng) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      latLng.latitude,
      latLng.longitude,
    );

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];
      String direccion = '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}';
      setState(() {
        _direccionSeleccionada = direccion;
      });
    } else {
      setState(() {
        _direccionSeleccionada = 'Dirección no encontrada';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _ubicacionActual != null
                ? () {
                    _mapController?.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: LatLng(
                              _ubicacionActual!.latitude, _ubicacionActual!.longitude),
                          zoom: 15.0,
                        ),
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: _ubicacionActual != null
                  ? LatLng(_ubicacionActual!.latitude, _ubicacionActual!.longitude)
                  : const LatLng(0, 0),
              zoom: 15.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            onCameraMove: (CameraPosition cameraPosition) {
              setState(() {
                _ubicacionSeleccionada = cameraPosition.target;
              });
              _actualizarDireccion(cameraPosition.target);
            },
            markers: _ubicacionSeleccionada != null
                ? {
                    Marker(
                      markerId: const MarkerId('ubicacion_seleccionada'),
                      position: _ubicacionSeleccionada!,
                      infoWindow: const InfoWindow(title: 'Ubicación Seleccionada'),
                    ),
                  }
                : {},
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.white.withOpacity(0.9),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _direccionSeleccionada,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _ubicacionSeleccionada != null
                        ? () {
                            Navigator.pop(context, {
                              'direccion': _direccionSeleccionada,
                              'latLng': _ubicacionSeleccionada,
                            });
                          }
                        : null,
                    child: const Text('Aceptar Ubicación'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}