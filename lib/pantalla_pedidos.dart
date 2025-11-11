import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PantallaPedidos extends StatefulWidget { 
  const PantallaPedidos({super.key});

  @override
  State<PantallaPedidos> createState() => _PantallaPedidosState();
}

class _PantallaPedidosState extends State<PantallaPedidos> {
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _currentUser == null
          ? _buildLoginPrompt()
          : _buildOrdersStream(),
    );
  }

  // Widget para mostrar si el usuario no está logueado
  Widget _buildLoginPrompt() {
     return Center(
       child: Padding(
         padding: const EdgeInsets.all(32.0),
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
              Icon(Icons.login_rounded, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 24),
              Text(
                'Inicia sesión',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
               Text(
                'Para ver tu historial de pedidos, por favor inicia sesión.',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.account_circle),
                label: const Text('Ir a Iniciar Sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                   Navigator.pushNamed(context, '/login').then((_) {
                      setState(() {
                        _currentUser = FirebaseAuth.instance.currentUser;
                      });
                   }); 
                },
              )
           ],
         ),
       ),
     );
  }

  // StreamBuilder que escucha los pedidos de Firestore
  Widget _buildOrdersStream() {
    return StreamBuilder<QuerySnapshot>(
      // Consulta SIN orderBy (no requiere índice)
      stream: FirebaseFirestore.instance
          .collection('Pedidos')
          .where('userId', isEqualTo: _currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        // Manejo de estados del Stream
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cargando pedidos...'),
              ],
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar pedidos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    snapshot.error.toString(),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  onPressed: () => setState(() {}),
                ),
              ],
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        // Ordenar manualmente por fecha (descendente)
        final pedidosDocs = snapshot.data!.docs.toList();
        pedidosDocs.sort((a, b) {
          final fechaA = (a.data() as Map<String, dynamic>)['fecha'] as Timestamp?;
          final fechaB = (b.data() as Map<String, dynamic>)['fecha'] as Timestamp?;
          if (fechaA == null || fechaB == null) return 0;
          return fechaB.compareTo(fechaA); // Descendente (más reciente primero)
        });
        
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: pedidosDocs.length,
            itemBuilder: (context, index) {
              return _buildOrderItem(pedidosDocs[index]); 
            },
          ),
        );
      },
    );
  }

  // Widget para CADA pedido
  Widget _buildOrderItem(QueryDocumentSnapshot pedidoDoc) {
     final pedidoData = pedidoDoc.data() as Map<String, dynamic>;

     final pedidoId = pedidoData['pedidoId'] ?? 'N/A';
     final fechaTimestamp = pedidoData['fecha'] as Timestamp?; 
     
     // Formatear fecha de manera más legible (SIN intl)
     String fechaFormateada = 'Fecha no disponible';
     if (fechaTimestamp != null) {
       final fecha = fechaTimestamp.toDate();
       final dia = fecha.day.toString().padLeft(2, '0');
       final mes = _obtenerNombreMes(fecha.month);
       final anio = fecha.year;
       final hora = fecha.hour.toString().padLeft(2, '0');
       final minuto = fecha.minute.toString().padLeft(2, '0');
       fechaFormateada = '$dia $mes $anio, $hora:$minuto';
     }
     
     final total = (pedidoData['total'] as num? ?? 0.0).toDouble();
     final estado = pedidoData['estado'] ?? 'Desconocido';
     final itemsCount = pedidoData['itemsCount'] ?? 0;

     // Generar ID corto de forma segura
    String pedidoIdCorto = pedidoId;
     if (pedidoId.contains('-')) {
       final partes = pedidoId.split('-');
       if (partes.isNotEmpty) {
         final ultimaParte = partes.last;
         pedidoIdCorto = ultimaParte.length > 6 ? ultimaParte.substring(0, 6) : ultimaParte;
       }
     } else {
       pedidoIdCorto = pedidoId.length > 6 ? pedidoId.substring(0, 6) : pedidoId;
     }

     // Lógica de color e icono basada en el estado
     Color estadoColor = Colors.orange; 
     IconData estadoIcon = Icons.local_shipping;
     
     if (estado == 'Entregado') { 
       estadoColor = Colors.green; 
       estadoIcon = Icons.check_circle_outline; 
     } else if (estado == 'Cancelado') { 
       estadoColor = Colors.red; 
       estadoIcon = Icons.cancel_outlined; 
     } else if (estado == 'Procesando') { 
       estadoColor = Colors.blue; 
       estadoIcon = Icons.inventory_2_outlined; 
     }

     return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _mostrarDetallesPedido(context, pedidoData, pedidoIdCorto), // Pasamos el ID corto
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ID del Pedido (más corto)
                  Expanded(
                    child: Text(
                      'Pedido #$pedidoIdCorto',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Chip de Estado
                  Chip(
                    avatar: Icon(estadoIcon, color: estadoColor, size: 18),
                    label: Text(
                      estado,
                      style: TextStyle(
                        color: estadoColor, 
                        fontSize: 12, 
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: estadoColor.withOpacity(0.15),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    side: BorderSide.none,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Información detallada
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fechaFormateada, 
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '$itemsCount ${itemsCount == 1 ? 'producto' : 'productos'}', 
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 12),
              
              // Total y Botón de Detalles
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Total: S/ ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 17,
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('Ver Detalles'),
                    onPressed: () => _mostrarDetallesPedido(context, pedidoData, pedidoIdCorto), // Pasamos el ID corto
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      side: BorderSide(color: Theme.of(context).primaryColor),
                      foregroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mostrar detalles completos del pedido en un modal
  void _mostrarDetallesPedido(BuildContext context, Map<String, dynamic> pedidoData, String pedidoIdCorto) {
    // El pedidoId completo (largo) está en pedidoData
    // final pedidoIdCompleto = pedidoData['pedidoId'] ?? 'N/A'; 
    
    final fechaTimestamp = pedidoData['fecha'] as Timestamp?;
    final total = (pedidoData['total'] as num? ?? 0.0).toDouble();
    final estado = pedidoData['estado'] ?? 'Desconocido';
    final productos = pedidoData['productos'] as List<dynamic>? ?? [];

    // --- ¡NUEVO! Extraer datos de entrega ---
    final tipoEntrega = pedidoData['tipoEntrega'] as String?;
    final direccionEntrega = pedidoData['direccionEntrega'] as String?;
    // final latLngEntrega = pedidoData['latLngEntrega'] as GeoPoint?; // No lo mostraremos, pero es bueno saber que está
    // ------------------------------------
    
    String fechaFormateada = 'Fecha no disponible';
    if (fechaTimestamp != null) {
      final fecha = fechaTimestamp.toDate();
      final dia = fecha.day.toString().padLeft(2, '0');
      final mes = _obtenerNombreMes(fecha.month);
      final anio = fecha.year;
      final hora = fecha.hour.toString().padLeft(2, '0');
      final minuto = fecha.minute.toString().padLeft(2, '0');
      fechaFormateada = '$dia $mes $anio, $hora:$minuto';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detalles del Pedido',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '#$pedidoIdCorto', // Usamos el ID corto en el header
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información del pedido
                    _buildInfoRow('Fecha:', fechaFormateada),
                    const SizedBox(height: 8),
                    _buildInfoRow('Estado:', estado),
                    const SizedBox(height: 8),
                    _buildInfoRow('Total:', 'S/ ${total.toStringAsFixed(2)}'),
                    
                    // --- ¡NUEVO! Sección de Información de Entrega ---
                    if (tipoEntrega != null) ...[
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey[200]),
                      const SizedBox(height: 16),
                      const Text(
                        'Método de Entrega:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            tipoEntrega == 'Delivery' 
                              ? Icons.local_shipping_outlined 
                              : Icons.store_mall_directory_outlined,
                            color: Colors.grey[700],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            tipoEntrega, // "Delivery" o "Recojo en tienda"
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      
                      // Mostrar dirección SOLO si es Delivery y la dirección existe
                      if (tipoEntrega == 'Delivery' && direccionEntrega != null && direccionEntrega.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: Colors.grey[700],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                direccionEntrega,
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 15,
                                  height: 1.4
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                    // --- Fin de la nueva sección ---
                    
                    const SizedBox(height: 24),
                    const Text(
                      'Productos:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Lista de productos
                    ...productos.map((producto) {
                      final nombre = producto['nombre'] ?? 'Sin nombre';
                      final precio = (producto['precio'] as num? ?? 0.0).toDouble();
                      final cantidad = producto['quantity'] ?? 1;
                      final imagenUrl = producto['imagen'] ?? '';
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Imagen
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imagenUrl.isNotEmpty
                                    ? Image.network(
                                        imagenUrl,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[200],
                                          child: Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[200],
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              
                              // Información
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Cantidad: $cantidad',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'S/ ${precio.toStringAsFixed(2)} c/u',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Subtotal
                              Text(
                                'S/ ${(precio * cantidad).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // Widget para mostrar cuando no hay pedidos
  Widget _buildEmptyState() {
     return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              'Aún no tienes pedidos',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Los pedidos que realices aparecerán aquí.\n¡Comienza a comprar ahora!',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Explorar Productos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // Esto te llevará a la primera pantalla de tu stack (usualmente tu home)
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Método auxiliar para obtener el nombre del mes en español
  String _obtenerNombreMes(int mes) {
    const meses = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return meses[mes];
  }
}