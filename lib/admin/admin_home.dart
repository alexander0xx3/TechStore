import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  static const String routeName = '/dashboard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // El fondo lo da el dashboard
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Resumen general de tu tienda',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
            const SizedBox(height: 32),

            // Metrics Cards
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('Pedidos').snapshots(),
              builder: (context, pedidosSnapshot) {
                if (!pedidosSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final pedidos = pedidosSnapshot.data!.docs;
                final totalVentas = pedidos.fold<double>(
                    0, (sum, doc) => sum + ((doc.data() as Map)['total'] ?? 0));
                final totalPedidos = pedidos.length;
                final pedidosPendientes = pedidos
                    .where(
                        (doc) => (doc.data() as Map)['estado'] == 'Pendiente')
                    .length;
                final pedidosEntregados = pedidos
                    .where(
                        (doc) => (doc.data() as Map)['estado'] == 'Entregado')
                    .length;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount =
                        width > 1100 ? 4 : (width > 700 ? 2 : 1);

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.6,
                      children: [
                        _buildMetricCard(
                          title: 'Ventas Totales',
                          value: 'S/ ${totalVentas.toStringAsFixed(2)}',
                          icon: Icons.attach_money,
                          color: Colors.green,
                          subtitle: '+12% vs mes anterior',
                        ),
                        _buildMetricCard(
                          title: 'Pedidos Totales',
                          value: totalPedidos.toString(),
                          icon: Icons.shopping_bag_outlined,
                          color: Colors.blue,
                          subtitle: '$pedidosEntregados entregados',
                        ),
                        _buildMetricCard(
                          title: 'Pendientes',
                          value: pedidosPendientes.toString(),
                          icon: Icons.timer_outlined,
                          color: Colors.orange,
                          subtitle: 'Requieren atención',
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('Productos')
                              .snapshots(),
                          builder: (context, prodSnap) {
                            final count = prodSnap.data?.docs.length ?? 0;
                            return _buildMetricCard(
                              title: 'Productos',
                              value: count.toString(),
                              icon: Icons.inventory_2_outlined,
                              color: Colors.purple,
                              subtitle: 'En catálogo',
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 40),

            // Recent Activity Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Actividad Reciente',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Ver todos'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Recent Orders Table/List
            Container(
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
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Pedidos')
                    .orderBy('fecha', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(48.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('No hay actividad reciente',
                                style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.grey[100],
                    ),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final total = data['total'] ?? 0.0;
                      final estado = data['estado'] ?? 'Desconocido';
                      final fecha = (data['fecha'] as Timestamp?)?.toDate();

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getEstadoColor(estado).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.receipt_outlined,
                            color: _getEstadoColor(estado),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          'Pedido #${docs[index].id.substring(0, 8)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        subtitle: Text(
                          fecha != null
                              ? DateFormat('dd MMM yyyy, HH:mm').format(fecha)
                              : 'Sin fecha',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'S/ ${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getEstadoColor(estado).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                estado,
                                style: TextStyle(
                                  color: _getEstadoColor(estado),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              // Optional: Add trend icon here
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'Pendiente':
        return Colors.orange;
      case 'Enviado':
        return Colors.blue;
      case 'Entregado':
        return Colors.green;
      case 'Cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
