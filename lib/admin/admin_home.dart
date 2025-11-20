import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  static const String routeName = '/';

  Widget _buildStatCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required String subtitle,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchStats() async {
    final results = await Future.wait([
      FirebaseFirestore.instance.collection('Pedidos').get(),
      FirebaseFirestore.instance.collection('Usuarios').get(),
      FirebaseFirestore.instance.collection('Productos').get(),
    ]);

    final pedidosSnapshot = results[0] as QuerySnapshot;
    final usuariosSnapshot = results[1] as QuerySnapshot;
    final productosSnapshot = results[2] as QuerySnapshot;

    double totalVentas = 0.0;
    int pedidosEsteMes = 0;
    final ahora = DateTime.now();
    
    for (var doc in pedidosSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final total = (data['total'] as num? ?? 0.0).toDouble();
      totalVentas += total;
      
      final fecha = (data['fecha'] as Timestamp?)?.toDate();
      if (fecha != null && fecha.month == ahora.month && fecha.year == ahora.year) {
        pedidosEsteMes++;
      }
    }

    return {
      'totalVentas': 'S/ ${totalVentas.toStringAsFixed(2)}',
      'totalPedidos': pedidosSnapshot.size.toString(),
      'pedidosEsteMes': pedidosEsteMes.toString(),
      'totalUsuarios': usuariosSnapshot.size.toString(),
      'totalProductos': productosSnapshot.size.toString(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido, Administrador',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Resumen general de tu tienda TechStore',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Statistics Cards
          FutureBuilder<Map<String, dynamic>>(
            future: _fetchStats(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.deepPurple,
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                return SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[300], size: 50),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar estadísticas',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final stats = snapshot.data!;

              return GridView.count(
                shrinkWrap: true,
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildStatCard(
                    context,
                    icon: Icons.attach_money,
                    title: 'Ventas Totales',
                    value: stats['totalVentas'] ?? 'S/ 0.00',
                    color: Colors.green,
                    subtitle: 'Ingresos acumulados',
                  ),
                  _buildStatCard(
                    context,
                    icon: Icons.shopping_cart,
                    title: 'Total Pedidos',
                    value: stats['totalPedidos'] ?? '0',
                    color: Colors.blue,
                    subtitle: 'Pedidos realizados',
                  ),
                  _buildStatCard(
                    context,
                    icon: Icons.people,
                    title: 'Total Usuarios',
                    value: stats['totalUsuarios'] ?? '0',
                    color: Colors.orange,
                    subtitle: 'Usuarios registrados',
                  ),
                  _buildStatCard(
                    context,
                    icon: Icons.inventory_2,
                    title: 'Total Productos',
                    value: stats['totalProductos'] ?? '0',
                    color: Colors.purple,
                    subtitle: 'Productos en stock',
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          // Recent Orders and Quick Actions
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recent Orders
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pedidos Recientes',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Ver todos'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance.collection('Pedidos')
                                  .orderBy('fecha', descending: true)
                                  .limit(6)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.receipt_long, size: 60, color: Colors.grey[400]),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No hay pedidos recientes',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                final pedidos = snapshot.data!.docs;

                                return ListView.separated(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: pedidos.length,
                                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
                                  itemBuilder: (context, index) {
                                    final data = pedidos[index].data() as Map<String, dynamic>;
                                    final userEmail = data['userEmail'] ?? 'N/A';
                                    final total = (data['total'] as num? ?? 0.0).toStringAsFixed(2);
                                    final estado = data['estado'] ?? 'N/A';
                                    final fecha = (data['fecha'] as Timestamp?)?.toDate();
                                    
                                    Color estadoColor = Colors.grey;
                                    if (estado == 'Procesando') estadoColor = Colors.orange;
                                    if (estado == 'Enviado') estadoColor = Colors.blue;
                                    if (estado == 'Entregado') estadoColor = Colors.green;
                                    if (estado == 'Cancelado') estadoColor = Colors.red;

                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      leading: CircleAvatar(
                                        backgroundColor: estadoColor.withOpacity(0.1),
                                        child: Icon(
                                          Icons.shopping_cart,
                                          color: estadoColor,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        userEmail,
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        'S/ $total • ${fecha != null ? '${fecha.day}/${fecha.month}/${fecha.year}' : 'N/A'}',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: estadoColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          estado,
                                          style: TextStyle(
                                            color: estadoColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // Quick Actions
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Acciones Rápidas',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildQuickAction(
                                icon: Icons.add,
                                title: 'Agregar Producto',
                                subtitle: 'Nuevo producto',
                                color: Colors.green,
                                onTap: () {
                                  // Navegar a productos con modal abierto
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildQuickAction(
                                icon: Icons.inventory_2,
                                title: 'Gestionar Stock',
                                subtitle: 'Control de inventario',
                                color: Colors.blue,
                                onTap: () {},
                              ),
                              const SizedBox(height: 12),
                              _buildQuickAction(
                                icon: Icons.analytics,
                                title: 'Ver Reportes',
                                subtitle: 'Estadísticas detalladas',
                                color: Colors.orange,
                                onTap: () {},
                              ),
                              const SizedBox(height: 12),
                              _buildQuickAction(
                                icon: Icons.settings,
                                title: 'Configuración',
                                subtitle: 'Ajustes de tienda',
                                color: Colors.purple,
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
      onTap: onTap,
    );
  }
}