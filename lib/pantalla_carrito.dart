import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Para LatLng
import 'main.dart';
import 'seleccionar_ubicacion.dart'; // Para el mapa

class CartScreen extends StatefulWidget {
  final VoidCallback? onExplore;

  const CartScreen({super.key, this.onExplore});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Constante para el IGV (18% en Perú)
  static const double _kTaxRate = 0.18;

  // --- ¡NUEVO! Dirección estática de la tienda ---
  static const String _kTiendaDireccion =
      "Av. Javier Prado Este 123, San Isidro, Lima";
  static final LatLng _kTiendaLatLng = LatLng(-12.0895, -77.0500);

  // --- ¡NUEVO! Variables de estado para la entrega ---
  String? _tipoEntregaSeleccionado;
  String? _direccionEntregaSeleccionada;
  LatLng? _latLngEntregaSeleccionado;

  void _removeProductCompletely(String productId) {
    final current = List<Map<String, dynamic>>.from(cartNotifier.value);
    cartNotifier.value =
        current.where((item) => item['id'] != productId).toList();
  }

  Future<void> _moveToWishlist(
      BuildContext context, Map<String, dynamic> product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Inicia sesión para guardar productos'),
          backgroundColor: Colors.orange[800],
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    final productId = product['id']?.toString() ?? 'no-id-${product.hashCode}';
    final productData = Map<String, dynamic>.from(product);
    productData.remove('quantity');
    productData['savedAt'] = FieldValue.serverTimestamp();

    try {
      await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(user.uid)
          .collection('Wishlist')
          .doc(productId)
          .set(productData);

      _removeProductCompletely(productId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product['nombre']} movido a tu Lista de Deseos'),
            backgroundColor: Theme.of(context).primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al mover producto: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: cartNotifier,
      builder: (context, cartItems, child) {
        final subtotal = getCartTotalPrice();
        final igv = subtotal * _kTaxRate;
        final totalFinal = subtotal + igv;
        final totalItems = getCartTotalItemCount();

        // --- ¡NUEVO! Reinicia la selección si el carrito se vacía ---
        if (cartItems.isEmpty && _tipoEntregaSeleccionado != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _tipoEntregaSeleccionado = null;
              _direccionEntregaSeleccionada = null;
              _latLngEntregaSeleccionado = null;
            });
          });
        }

        return Column(
          children: [
            Expanded(
              child: cartItems.isEmpty
                  ? _buildEmptyCart(context)
                  : _buildCartList(cartItems, context),
            ),
            if (cartItems.isNotEmpty)
              _buildBottomBar(subtotal, igv, totalFinal, totalItems, context),
          ],
        );
      },
    );
  }

  Widget _buildCartItem(BuildContext context, Map<String, dynamic> product,
      List<Map<String, dynamic>> cartItems) {
    final nombre = product['nombre'] ?? 'Sin nombre';
    final precio = (product['precio'] as num? ?? 0.0).toDouble();
    final imagenUrl = product['imagen'] ?? '';
    final quantity = (product['quantity'] as num? ?? 1).toInt();
    final productId = product['id']?.toString() ?? 'no-id-${product.hashCode}';

    return Dismissible(
      key: ValueKey(productId),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
            color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline, color: Colors.red[700], size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar Producto'),
            content: Text('¿Quitar "$nombre" del carrito?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar')),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Eliminar',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _removeProductCompletely(productId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$nombre" eliminado'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'DESHACER',
              textColor: Theme.of(context).colorScheme.inversePrimary,
              onPressed: () {
                addProductToCart(product);
              },
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _fixGoogleDriveUrl(imagenUrl),
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, p) => p == null
                      ? child
                      : Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey[200],
                          child: const Center(
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))),
                  errorBuilder: (context, error, stackTrace) => Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey[200],
                      child: Icon(Icons.broken_image_outlined,
                          size: 30, color: Colors.grey[400])),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text('S/ ${precio.toStringAsFixed(2)}',
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontSize: 14)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _buildQuantityButton(context, Icons.remove, () {
                              removeProductFromCart(product);
                            }),
                            Container(
                              width: 35,
                              alignment: Alignment.center,
                              child: Text('$quantity',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                            ),
                            _buildQuantityButton(context, Icons.add, () {
                              addProductToCart(product);
                            }, isAdd: true),
                          ],
                        ),
                        Text(
                          'S/ ${(precio * quantity).toStringAsFixed(2)}',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Theme.of(context).primaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 30,
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.bookmark_add_outlined,
                            size: 16, color: Colors.grey[600]),
                        label: Text('Mover a Lista de Deseos',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: () {
                          _moveToWishlist(context, product);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ¡WIDGET ACTUALIZADO! ---
  Widget _buildBottomBar(double subtotal, double igv, double totalFinal,
      int totalItems, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -3))
        ],
        border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: SafeArea(
        bottom: true,
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPriceRow("Subtotal:", 'S/ ${subtotal.toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            _buildPriceRow("IGV (18%):", 'S/ ${igv.toStringAsFixed(2)}'),

            // --- ¡NUEVA SECCIÓN DE ENTREGA! ---
            if (_tipoEntregaSeleccionado != null)
              _buildInfoEntregaSeleccionada(
                  context, subtotal, igv, totalFinal, totalItems),
            // --- FIN NUEVA SECCIÓN ---

            const SizedBox(height: 4),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 8),
            _buildPriceRow(
                "Total a Pagar:", 'S/ ${totalFinal.toStringAsFixed(2)}',
                isTotal: true),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // --- ¡LÓGICA DEL BOTÓN ACTUALIZADA! ---
                onPressed: () {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    Navigator.pushNamed(context, '/login');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Inicia sesión para continuar'),
                        backgroundColor: Colors.orange[800],
                      ),
                    );
                  } else if (_tipoEntregaSeleccionado == null) {
                    // 1. Si AÚN NO ha seleccionado, muestra el modal de selección
                    _showMetodoEntregaDialog(
                        context, subtotal, igv, totalFinal, totalItems);
                  } else {
                    // 2. Si YA seleccionó, muestra la confirmación final
                    _showCheckoutDialog(
                      context, subtotal, igv, totalFinal, totalItems,
                      tipoEntrega: _tipoEntregaSeleccionado!,
                      direccion:
                          _direccionEntregaSeleccionada, // Pasa la dirección (cliente o tienda)
                      latLng:
                          _latLngEntregaSeleccionado, // Pasa el LatLng (cliente o tienda)
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                // --- ¡TEXTO DEL BOTÓN ACTUALIZADO! ---
                child: Text(_tipoEntregaSeleccionado == null
                    ? 'Elegir Método de Entrega'
                    : 'Confirmar Pedido'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ¡NUEVO WIDGET AUXILIAR! ---
  // Muestra la dirección elegida y el botón "Cambiar"
  Widget _buildInfoEntregaSeleccionada(BuildContext context, double subtotal,
      double igv, double totalFinal, int totalItems) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _tipoEntregaSeleccionado == 'Recojo en tienda'
                    ? 'Recogerás en:'
                    : 'Se enviará a:',
                style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
              // Botón para cambiar la selección
              TextButton(
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact),
                child: const Text('Cambiar'),
                onPressed: () {
                  // Vuelve a abrir el modal de selección
                  _showMetodoEntregaDialog(
                      context, subtotal, igv, totalFinal, totalItems);
                },
              )
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                  _tipoEntregaSeleccionado == 'Recojo en tienda'
                      ? Icons.store_mall_directory_outlined
                      : Icons.location_on_outlined,
                  color: Theme.of(context).primaryColor,
                  size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _direccionEntregaSeleccionada ?? 'No seleccionada',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: isTotal
                ? Theme.of(context).textTheme.bodyLarge?.color
                : Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // --- ¡FUNCIÓN ACTUALIZADA! ---
  // Ahora actualiza el estado en lugar de llamar a _showCheckoutDialog
  void _showMetodoEntregaDialog(BuildContext context, double subtotal,
      double igv, double totalFinal, int totalItems) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.local_shipping_outlined,
                color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('Método de Entrega'),
          ],
        ),
        content: const Text('¿Cómo prefieres recibir tu pedido?'),
        actionsPadding: const EdgeInsets.all(16.0),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. RECOJO EN TIENDA ---
              OutlinedButton.icon(
                icon: const Icon(Icons.store_mall_directory_outlined),
                label: const Text('Recojo en Tienda'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(dialogContext); // Cierra este diálogo
                  // --- ¡CAMBIO! Actualiza el estado ---
                  setState(() {
                    _tipoEntregaSeleccionado = 'Recojo en tienda';
                    _direccionEntregaSeleccionada =
                        _kTiendaDireccion; // Usamos la constante
                    _latLngEntregaSeleccionado =
                        _kTiendaLatLng; // Usamos la constante
                  });
                },
              ),
              const SizedBox(height: 10),

              // --- 2. USAR DIRECCIÓN GUARDADA ---
              OutlinedButton.icon(
                icon: const Icon(Icons.bookmark_border_rounded),
                label: const Text('Usar Dirección Guardada'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(dialogContext); // Cierra este diálogo
                  // --- Llama al nuevo diálogo de selección (esto no cambia) ---
                  _showSeleccionarDireccionDialog(
                      context, subtotal, igv, totalFinal, totalItems);
                },
              ),
              const SizedBox(height: 10),

              // --- 3. ENVIAR A UBICACIÓN NUEVA ---
              ElevatedButton.icon(
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Enviar a Ubicación Nueva'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  Navigator.pop(dialogContext); // Cierra este diálogo

                  // Abre la pantalla de seleccionar ubicación
                  final resultado = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const SeleccionarUbicacionScreen()),
                  );

                  if (resultado != null &&
                      resultado.containsKey('direccion') &&
                      resultado.containsKey('latLng')) {
                    // --- ¡CAMBIO! Actualiza el estado ---
                    setState(() {
                      _tipoEntregaSeleccionado = 'Delivery';
                      _direccionEntregaSeleccionada = resultado['direccion'];
                      _latLngEntregaSeleccionado = resultado['latLng'];
                    });
                  }
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  // --- ¡FUNCIÓN ACTUALIZADA! ---
  // Ahora actualiza el estado en lugar de llamar a _showCheckoutDialog
  void _showSeleccionarDireccionDialog(BuildContext context, double subtotal,
      double igv, double totalFinal, int totalItems) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // No debería pasar si llegamos aquí

    final stream = FirebaseFirestore.instance
        .collection('Usuarios')
        .doc(user.uid)
        .collection('Direcciones')
        .orderBy('creadoEn', descending: true)
        .snapshots();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Elige una Dirección'),
        contentPadding: const EdgeInsets.fromLTRB(0, 20, 0, 24),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_off_outlined,
                          size: 50, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'No tienes direcciones guardadas.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final direcciones = snapshot.data!.docs;

              return ListView.separated(
                shrinkWrap: true,
                itemCount: direcciones.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: Colors.grey[200]),
                itemBuilder: (context, index) {
                  final doc = direcciones[index];
                  final data = doc.data() as Map<String, dynamic>;

                  final nombre = data['nombre'] ?? 'Sin nombre';
                  final direccion = data['direccion'] ?? 'Sin dirección';
                  final ciudad = data['ciudad'] ?? 'Sin ciudad';
                  final GeoPoint? geoPoint =
                      data['ubicacion']; // El campo clave

                  final bool esValida = geoPoint != null;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 8.0),
                    leading: Icon(
                      nombre.toLowerCase() == 'casa'
                          ? Icons.home_outlined
                          : nombre.toLowerCase() == 'oficina'
                              ? Icons.work_outline
                              : Icons.location_on_outlined,
                      color: esValida
                          ? Theme.of(context).primaryColor
                          : Colors.grey[400],
                    ),
                    title: Text(nombre,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      "$direccion, $ciudad\n${esValida ? '' : '(No válida para delivery)'}",
                      style: TextStyle(
                          fontSize: 13,
                          color: esValida ? Colors.grey[600] : Colors.red[300]),
                    ),
                    isThreeLine: !esValida,
                    enabled:
                        esValida, // Deshabilita el ListTile si no hay GeoPoint
                    onTap: () {
                      if (!esValida) return; // Doble seguridad

                      final LatLng latLng =
                          LatLng(geoPoint.latitude, geoPoint.longitude);
                      final String direccionCompleta = "$direccion, $ciudad";

                      Navigator.pop(dialogContext); // Cierra este diálogo

                      // --- ¡CAMBIO! Actualiza el estado ---
                      setState(() {
                        _tipoEntregaSeleccionado = 'Delivery';
                        _direccionEntregaSeleccionada = direccionCompleta;
                        _latLngEntregaSeleccionado = latLng;
                      });
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  // --- ¡FUNCIÓN DE DIÁLOGO DE PAGO FINAL! ---
  // (La firma del método ha cambiado para aceptar los nuevos parámetros)
  void _showCheckoutDialog(BuildContext context, double subtotal, double igv,
      double totalFinal, int totalItems,
      {required String tipoEntrega,
      String? direccion,
      LatLng? latLng} // Parámetros nuevos
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Pedido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumen de tu pedido:'),
            const SizedBox(height: 12),

            // --- NUEVA INFORMACIÓN EN EL RESUMEN ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!)),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.shopping_bag_outlined,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text('$totalItems productos',
                          style: TextStyle(
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (direccion != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                            tipoEntrega == 'Delivery'
                                ? Icons.location_on_outlined
                                : Icons.store_mall_directory_outlined,
                            size: 16,
                            color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Text(direccion,
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 13))),
                      ],
                    ),
                ],
              ),
            ),
            // --- FIN DE NUEVA INFORMACIÓN ---

            const SizedBox(height: 8),
            _buildPriceRow("Subtotal:", 'S/ ${subtotal.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _buildPriceRow("IGV (18%):", 'S/ ${igv.toStringAsFixed(2)}'),
            const Divider(height: 16),
            _buildPriceRow("Total:", 'S/ ${totalFinal.toStringAsFixed(2)}',
                isTotal: true),
          ],
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Revisar Pedido'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Confirmar y Pagar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColorDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              navigator.pop(); // Cierra el diálogo de confirmación

              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: const Row(children: [
                      Icon(Icons.error_outline, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Debes iniciar sesión')
                    ]),
                    backgroundColor: Colors.red[700],
                  ),
                );
                navigator.pushNamed('/login');
                return;
              }

              final timestamp = DateTime.now().millisecondsSinceEpoch;
              final userIdShort =
                  user.uid.length >= 6 ? user.uid.substring(0, 6) : user.uid;
              final pedidoId = 'ORD-$timestamp-$userIdShort';
              final fechaPedido = Timestamp.now();
              final List<Map<String, dynamic>> itemsPedido = cartNotifier.value
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList();

              // Muestra el diálogo de "Procesando"
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) => WillPopScope(
                  onWillPop: () async => false,
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Procesando pedido...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );

              try {
                // --- ¡LÓGICA DE GUARDADO EN FIRESTORE ACTUALIZADA! ---
                await FirebaseFirestore.instance
                    .collection('Pedidos')
                    .doc(pedidoId)
                    .set({
                  'userId': user.uid,
                  'userEmail': user.email ?? 'Sin email',
                  'userName': user.displayName ?? 'Usuario',
                  'pedidoId': pedidoId,
                  'fecha': fechaPedido,
                  'subtotal': subtotal,
                  'igv': igv,
                  'total': totalFinal,
                  'itemsCount': totalItems,
                  'estado': 'Pendiente',
                  'productos': itemsPedido
                      .map((item) => {
                            'id': item['id'] ?? '',
                            'nombre': item['nombre'] ?? 'Producto sin nombre',
                            'precio':
                                (item['precio'] as num?)?.toDouble() ?? 0.0,
                            'quantity':
                                (item['quantity'] as num?)?.toInt() ?? 1,
                            'imagen': item['imagen'] ?? '',
                          })
                      .toList(),
                  'createdAt': FieldValue.serverTimestamp(),

                  // --- CAMPOS NUEVOS SIMPLIFICADOS ---
                  'tipoEntrega': tipoEntrega, // "Delivery" o "Recojo en tienda"
                  'direccionEntrega':
                      direccion, // Guarda la dirección (cliente o tienda)
                  'latLngEntrega': latLng != null
                      ? GeoPoint(
                          latLng.latitude,
                          latLng
                              .longitude) // Guarda el GeoPoint (cliente o tienda)
                      : null,
                });
                // --- FIN DE CAMPOS NUEVOS ---

                navigator.pop(); // Cerrar indicador de carga

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: const Row(children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                            Text('¡Pedido realizado con éxito!',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            SizedBox(height: 4),
                            Text('Puedes ver tu pedido en "Mis Pedidos"',
                                style: TextStyle(fontSize: 12)),
                          ])),
                    ]),
                    backgroundColor: Colors.green[700],
                    duration: const Duration(seconds: 4),
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'Ver',
                      textColor: Colors.white,
                      onPressed: () {
                        navigator.pushNamed('/orders');
                      },
                    ),
                  ),
                );
                cartNotifier.value = [];
              } catch (e) {
                navigator.pop(); // Cerrar indicador de carga
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Row(children: [
                            Icon(Icons.error_outline, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Error al procesar el pedido',
                                style: TextStyle(fontWeight: FontWeight.w600))
                          ]),
                          const SizedBox(height: 8),
                          const Text('Por favor, intenta nuevamente.',
                              style: TextStyle(fontSize: 12)),
                          Text('Error: ${e.toString()}',
                              style: const TextStyle(fontSize: 10),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ]),
                    backgroundColor: Colors.red[700],
                    duration: const Duration(seconds: 6),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // --- El resto de tus funciones auxiliares ---
  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_checkout_rounded,
                size: 120, color: Colors.grey[350]),
            const SizedBox(height: 24),
            Text(
              'Tu carrito está vacío',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Text(
              'Agrega algunos productos increíbles\npara comenzar a comprar.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 16, color: Colors.grey[500], height: 1.4),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Explorar Productos'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () {
                widget.onExplore?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartList(
      List<Map<String, dynamic>> cartItems, BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.08),
              border: Border(bottom: BorderSide(color: Colors.grey[300]!))),
          child: Text(
            '${getCartTotalItemCount()} ${getCartTotalItemCount() == 1 ? 'producto' : 'productos'} en tu carrito',
            style: TextStyle(
              color: Theme.of(context).primaryColorDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: cartItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = cartItems[index];
              return _buildCartItem(context, product, cartItems);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityButton(
      BuildContext context, IconData icon, VoidCallback onPressed,
      {bool isAdd = false}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
            color: isAdd
                ? Theme.of(context).primaryColor.withOpacity(0.15)
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: isAdd
                    ? Theme.of(context).primaryColor.withOpacity(0.3)
                    : Colors.grey[300]!,
                width: 1)),
        child: Icon(icon,
            size: 16,
            color: isAdd ? Theme.of(context).primaryColor : Colors.grey[700]),
      ),
    );
  }

  String _fixGoogleDriveUrl(String url) {
    if (url.contains('drive.google.com')) {
      final idRegex = RegExp(r'\/d\/([a-zA-Z0-9_-]+)');
      final match = idRegex.firstMatch(url);
      if (match != null) {
        final fileId = match.group(1);
        // Usar proxy wsrv.nl para evitar CORS en Web
        return 'https://wsrv.nl/?url=https://drive.google.com/uc?id=$fileId';
      }
    }
    return url;
  }
}
