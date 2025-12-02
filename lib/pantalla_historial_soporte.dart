import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PantallaHistorialSoporte extends StatelessWidget {
  const PantallaHistorialSoporte({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tickets de Soporte'),
        centerTitle: true,
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text('Inicia sesión para ver tus tickets'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Soporte')
                  .where('userId', isEqualTo: user.uid)
                  // .orderBy('fecha', descending: true) // Eliminado para evitar error de índice
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error al cargar tickets: ${snapshot.error}'),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                // Ordenar en memoria
                docs.sort((a, b) {
                  final fechaA =
                      (a.data() as Map<String, dynamic>)['fecha'] as Timestamp?;
                  final fechaB =
                      (b.data() as Map<String, dynamic>)['fecha'] as Timestamp?;
                  if (fechaA == null || fechaB == null) return 0;
                  return fechaB.compareTo(fechaA); // Descendente
                });

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.support_agent,
                            size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No tienes tickets de soporte',
                          style: TextStyle(
                            fontSize: 18,
                            color: isDark ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildTicketCard(context, data);
                  },
                );
              },
            ),
    );
  }

  Widget _buildTicketCard(BuildContext context, Map<String, dynamic> data) {
    final fecha = (data['fecha'] as Timestamp?)?.toDate();
    final fechaStr = fecha != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(fecha)
        : 'Fecha desconocida';
    final estado = data['estado'] ?? 'Pendiente';
    final colorEstado = _getColorEstado(estado);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).cardColor,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorEstado.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.confirmation_number_outlined, color: colorEstado),
        ),
        title: Text(
          data['asunto'] ?? 'Sin asunto',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          fechaStr,
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: Chip(
          label: Text(
            estado,
            style: TextStyle(
              color: colorEstado,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          backgroundColor: colorEstado.withOpacity(0.1),
          side: BorderSide.none,
          padding: EdgeInsets.zero,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data['pedidoId'] != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_bag_outlined,
                            size: 16, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Pedido Relacionado: #${data['pedidoId']}',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).primaryColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Descripción:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data['descripcion'] ?? 'Sin descripción',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                if (data['imagenUrl'] != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      data['imagenUrl'],
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Text('Error al cargar imagen'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'Pendiente':
        return Colors.orange;
      case 'En Proceso':
        return Colors.blue;
      case 'Resuelto':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
