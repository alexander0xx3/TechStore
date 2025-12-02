import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminSoporteScreen extends StatefulWidget {
  static const String routeName = '/admin-soporte';

  const AdminSoporteScreen({super.key});

  @override
  State<AdminSoporteScreen> createState() => _AdminSoporteScreenState();
}

class _AdminSoporteScreenState extends State<AdminSoporteScreen> {
  String _filtroEstado = 'Todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                      'Soporte Técnico',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gestiona tickets y consultas de clientes',
                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                    ),
                  ],
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Soporte')
                      .where('estado', isEqualTo: 'Pendiente')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.docs.length ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED), // Naranja muy claro
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                      ),
                      child: Text(
                        '$count pendientes',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Filtros
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todos'),
                  const SizedBox(width: 12),
                  _buildFilterChip('Pendiente'),
                  const SizedBox(width: 12),
                  _buildFilterChip('En Proceso'),
                  const SizedBox(width: 12),
                  _buildFilterChip('Resuelto'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Lista de tickets
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
                child: StreamBuilder<QuerySnapshot>(
                  stream: _buildQuery(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var docs = snapshot.data?.docs ?? [];

                    // Ordenar por fecha
                    docs.sort((a, b) {
                      final fechaA = (a.data() as Map<String, dynamic>)['fecha']
                          as Timestamp?;
                      final fechaB = (b.data() as Map<String, dynamic>)['fecha']
                          as Timestamp?;
                      if (fechaA == null || fechaB == null) return 0;
                      return fechaB.compareTo(fechaA);
                    });

                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.support_agent_outlined,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              _filtroEstado == 'Todos'
                                  ? 'No hay tickets'
                                  : 'No hay tickets "$_filtroEstado"',
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
                        return _buildTicketCard(id, data);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  Stream<QuerySnapshot> _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('Soporte');

    if (_filtroEstado != 'Todos') {
      query = query.where('estado', isEqualTo: _filtroEstado);
    }

    return query.snapshots();
  }

  Widget _buildTicketCard(String id, Map<String, dynamic> data) {
    final asunto = data['asunto'] ?? 'Sin asunto';
    final descripcion = data['descripcion'] ?? '';
    final estado = data['estado'] ?? 'Pendiente';
    final fecha = (data['fecha'] as Timestamp?)?.toDate();
    final imagenUrl = data['imagenUrl'] ?? '';

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
            _getIconEstado(estado),
            color: _getColorEstado(estado),
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                asunto,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black87,
                ),
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
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            fecha != null
                ? DateFormat('dd MMM yyyy, HH:mm').format(fecha)
                : 'Sin fecha',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
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
                const Text(
                  'Descripción',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  descripcion.isNotEmpty ? descripcion : 'Sin descripción',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                if (imagenUrl.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Adjunto',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imagenUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined, size: 48),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
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
                  children: [
                    _buildActionButton(
                        id, 'Pendiente', Colors.orange, Icons.timer_outlined),
                    _buildActionButton(id, 'En Proceso', Colors.blue,
                        Icons.engineering_outlined),
                    _buildActionButton(id, 'Resuelto', Colors.green,
                        Icons.check_circle_outline),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
          .collection('Soporte')
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
        return Colors.orange;
      case 'En Proceso':
        return Colors.blue;
      case 'Resuelto':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconEstado(String estado) {
    switch (estado) {
      case 'Pendiente':
        return Icons.timer_outlined;
      case 'En Proceso':
        return Icons.engineering_outlined;
      case 'Resuelto':
        return Icons.check_circle_outline;
      default:
        return Icons.support_agent_outlined;
    }
  }
}
