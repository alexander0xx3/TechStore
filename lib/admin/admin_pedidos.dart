import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminPedidosScreen extends StatefulWidget {
  const AdminPedidosScreen({super.key});

  static const String routeName = '/pedidos';

  @override
  State<AdminPedidosScreen> createState() => _AdminPedidosScreenState();
}

class _AdminPedidosScreenState extends State<AdminPedidosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filtroEstado = 'Todos';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _filtroEstado = 'Todos'; // Resetear filtro al cambiar de tab
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- FUNCIÓN CRÍTICA PARA CORREGIR IMÁGENES EN WEB ---
  String _fixGoogleDriveUrl(String url) {
    if (url.isEmpty) return '';

    // Verificamos si es un enlace de Google Drive
    if (url.contains('drive.google.com') || url.contains('docs.google.com')) {
      String? fileId;

      // CASO 1: Formato ".../file/d/EL_ID/..."
      final match1 = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(url);
      if (match1 != null) {
        fileId = match1.group(1);
      }
      // CASO 2: Formato "...?id=EL_ID..." (común en enlaces generados por script)
      else {
        final match2 = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)').firstMatch(url);
        if (match2 != null) {
          fileId = match2.group(1);
        }
      }

      // Si encontramos el ID, usamos el proxy wsrv.nl
      if (fileId != null) {
        // wsrv.nl evita el bloqueo CORS (Access-Control-Allow-Origin) en navegadores
        return 'https://wsrv.nl/?url=https://drive.google.com/uc?id=$fileId';
      }
    }

    // Si no es de Drive, devolvemos la URL original
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.transparent, // O Colors.grey[100] si prefieres fondo
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pedidos',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gestiona y actualiza el estado de los pedidos',
                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                    ),
                  ],
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Pedidos')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.docs.length ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF), // Azul muy claro
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        '$count pedidos totales',
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tabs
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(25.0),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(25.0),
                  color: const Color(0xFF2563EB),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Delivery'),
                  Tab(text: 'Recojo en Tienda'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Filtros (Dinámicos según el Tab)
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _buildFiltrosPorTab(_tabController.index),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Lista de pedidos
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrdersList('Delivery'),
                    _buildOrdersList('Recojo en tienda'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFiltrosPorTab(int index) {
    List<String> estados = [];
    if (index == 0) {
      // Delivery
      estados = ['Todos', 'Pendiente', 'Enviado', 'Entregado', 'Cancelado'];
    } else {
      // Recojo en Tienda
      estados = [
        'Todos',
        'Pendiente',
        'Preparando pedido',
        'Listo para recoger',
        'Entregado',
        'Cancelado'
      ];
    }

    return estados.map((estado) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: _buildFilterChip(estado),
      );
    }).toList();
  }

  Widget _buildFilterChip(String estado) {
    final isSelected = _filtroEstado == estado;
    return InkWell(
      onTap: () => setState(() => _filtroEstado = estado),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : Colors.grey[300]!,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          estado,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList(String tipoEntregaFiltro) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Pedidos')
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data?.docs ?? [];

        // --- FILTRADO EN EL CLIENTE ---
        final docs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          // 1. Filtrar por Tipo de Entrega
          final tipoEntrega = data['tipoEntrega'] ?? 'Delivery';
          // Normalizar strings para comparación segura
          final esRecojo =
              tipoEntrega.toString().toLowerCase().contains('recojo');
          final esDeliveryTab = tipoEntregaFiltro == 'Delivery';

          if (esDeliveryTab && esRecojo) return false;
          if (!esDeliveryTab && !esRecojo) return false;

          // 2. Filtrar por Estado
          if (_filtroEstado == 'Todos') return true;

          final estado = data['estado'] ?? 'Pendiente';
          if (_filtroEstado == 'Pendiente') {
            return estado == 'Pendiente' || estado == 'Procesando';
          }
          return estado == _filtroEstado;
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined,
                    size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No hay pedidos de $tipoEntregaFiltro',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: docs.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: Colors.grey[100],
          ),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;
            return _buildPedidoItem(id, data, tipoEntregaFiltro);
          },
        );
      },
    );
  }

  Widget _buildPedidoItem(
      String id, Map<String, dynamic> data, String tipoTab) {
    final fecha = (data['fecha'] as Timestamp?)?.toDate();
    final total = (data['total'] as num?)?.toDouble() ?? 0.0;
    final estado = data['estado'] ?? 'Pendiente';

    List<dynamic> productos = [];
    final rawProductos = data['productos'];
    final rawItems = data['items'];

    if (rawProductos != null &&
        rawProductos is List &&
        rawProductos.isNotEmpty) {
      productos = rawProductos;
    } else if (rawItems != null && rawItems is List && rawItems.isNotEmpty) {
      productos = rawItems;
    }

    final direccion = data['direccion'] ?? 'Sin dirección';
    final userName = data['userName'] ?? 'Usuario Desconocido';
    final userEmail = data['userEmail'] ?? 'Sin email';
    final tipoEntrega = data['tipoEntrega'] ?? 'Delivery';

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getColorEstado(estado).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.receipt_outlined,
            color: _getColorEstado(estado),
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(
              'Pedido #${id.substring(0, 8)}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getColorEstado(estado).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                estado,
                style: TextStyle(
                  color: _getColorEstado(estado),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                fecha != null
                    ? DateFormat('dd MMM yyyy, HH:mm').format(fecha)
                    : 'Sin fecha',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$userName ($userEmail)',
              style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'S/ ${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: tipoEntrega == 'Recojo en tienda'
                    ? Colors.purple.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tipoEntrega,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: tipoEntrega == 'Recojo en tienda'
                      ? Colors.purple
                      : Colors.blue,
                ),
              ),
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info de Entrega
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                        tipoEntrega == 'Recojo en tienda'
                            ? Icons.store
                            : Icons.location_on_outlined,
                        size: 18,
                        color: Colors.grey[500]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tipoEntrega,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          if (tipoEntrega == 'Delivery')
                            Text(
                              direccion,
                              style: TextStyle(
                                  color: Colors.grey[700], fontSize: 13),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Lista de Productos Detallada
                const Text(
                  'Productos',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                if (productos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('No hay productos registrados en este pedido.',
                        style: TextStyle(color: Colors.grey)),
                  )
                else
                  ...productos.map((item) {
                    final nombre = item['nombre'] ?? 'Producto';
                    final cantidad = item['quantity'] ?? item['cantidad'] ?? 1;
                    final precio = (item['precio'] as num?)?.toDouble() ?? 0.0;
                    final imagen = item['imagen'] ?? '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          // Imagen pequeña
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: Colors.grey[200],
                            ),
                            child: imagen.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      // --- AQUÍ APLICAMOS EL FIX ---
                                      _fixGoogleDriveUrl(imagen),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(
                                            Icons.image_not_supported,
                                            size: 20,
                                            color: Colors.grey);
                                      },
                                    ),
                                  )
                                : const Icon(Icons.image,
                                    size: 20, color: Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombre,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '$cantidad x S/ ${precio.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'S/ ${(precio * cantidad).toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 24),

                // Botones de Acción
                const Text(
                  'Actualizar Estado',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _buildActionButtonsForType(id, tipoTab),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtonsForType(String id, String tipoTab) {
    if (tipoTab == 'Delivery') {
      return [
        _buildActionButton(
            id, 'Pendiente', Colors.orange, Icons.timer_outlined),
        _buildActionButton(
            id, 'Enviado', Colors.blue, Icons.local_shipping_outlined),
        _buildActionButton(
            id, 'Entregado', Colors.green, Icons.check_circle_outline),
        _buildActionButton(id, 'Cancelado', Colors.red, Icons.cancel_outlined),
      ];
    } else {
      // Recojo en Tienda
      return [
        _buildActionButton(
            id, 'Pendiente', Colors.orange, Icons.timer_outlined),
        _buildActionButton(
            id, 'Preparando pedido', Colors.amber, Icons.soup_kitchen),
        _buildActionButton(id, 'Listo para recoger', Colors.indigo,
            Icons.shopping_bag_outlined),
        _buildActionButton(
            id, 'Entregado', Colors.green, Icons.check_circle_outline),
        _buildActionButton(id, 'Cancelado', Colors.red, Icons.cancel_outlined),
      ];
    }
  }

  Widget _buildActionButton(
      String id, String estado, Color color, IconData icon) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(estado),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        elevation: 0,
        side: BorderSide(color: color.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: () => _actualizarEstado(id, estado),
    );
  }

  Future<void> _actualizarEstado(String id, String nuevoEstado) async {
    try {
      await FirebaseFirestore.instance
          .collection('Pedidos')
          .doc(id)
          .update({'estado': nuevoEstado});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado actualizado a $nuevoEstado'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'Pendiente':
      case 'Procesando':
        return Colors.orange;
      case 'Preparando pedido':
        return Colors.amber;
      case 'Enviado':
        return Colors.blue;
      case 'Listo para recoger':
        return Colors.indigo;
      case 'Entregado':
        return Colors.green;
      case 'Cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
