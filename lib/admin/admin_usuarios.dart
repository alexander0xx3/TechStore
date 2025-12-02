import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminUsuariosScreen extends StatefulWidget {
  const AdminUsuariosScreen({super.key});

  static const String routeName = '/usuarios';

  @override
  State<AdminUsuariosScreen> createState() => _AdminUsuariosScreenState();
}

class _AdminUsuariosScreenState extends State<AdminUsuariosScreen> {
  final CollectionReference _usersRef =
      FirebaseFirestore.instance.collection('Users');
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filtroRol = 'Todos';

  String _fixGoogleDriveUrl(String url) {
    if (url.contains('drive.google.com')) {
      final idRegex = RegExp(r'\/d\/([a-zA-Z0-9_-]+)');
      final match = idRegex.firstMatch(url);
      if (match != null) {
        final fileId = match.group(1);
        return 'https://wsrv.nl/?url=https://drive.google.com/uc?id=$fileId';
      }
    }
    return url;
  }

  Future<void> _toggleAdminRole(
      String userId, bool currentIsAdmin, String email) async {
    try {
      // Si es admin, lo pasamos a 'user', si no, a 'admin'
      final newRole = currentIsAdmin ? 'user' : 'admin';

      await _usersRef.doc(userId).update({
        'role': newRole,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newRole == 'admin'
                ? '$email ahora es administrador'
                : 'Rol de admin removido de $email'),
            backgroundColor: newRole == 'admin' ? Colors.green : Colors.orange,
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
                      'Usuarios',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Administra roles y permisos',
                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                    ),
                  ],
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: _usersRef.snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.docs.length ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF), // Morado muy claro
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE9D5FF)),
                      ),
                      child: Text(
                        '$count usuarios',
                        style: const TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Filtros y Búsqueda
            Row(
              children: [
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
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o email...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon:
                                    const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filtroRol,
                      icon: Icon(Icons.keyboard_arrow_down,
                          color: Colors.grey[600]),
                      items: ['Todos', 'Admins', 'Usuarios']
                          .map((rol) => DropdownMenuItem(
                                value: rol,
                                child: Text(rol,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _filtroRol = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Lista
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
                  stream: _usersRef.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var docs = snapshot.data?.docs ?? [];

                    // Filtros
                    if (_searchQuery.isNotEmpty) {
                      docs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final email =
                            data['email']?.toString().toLowerCase() ?? '';
                        final nombre =
                            data['nombre']?.toString().toLowerCase() ?? '';
                        return email.contains(_searchQuery.toLowerCase()) ||
                            nombre.contains(_searchQuery.toLowerCase());
                      }).toList();
                    }

                    if (_filtroRol == 'Admins') {
                      docs = docs
                          .where(
                              (doc) => (doc.data() as Map)['role'] == 'admin')
                          .toList();
                    } else if (_filtroRol == 'Usuarios') {
                      docs = docs
                          .where(
                              (doc) => (doc.data() as Map)['role'] != 'admin')
                          .toList();
                    }

                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('No se encontraron usuarios',
                                style: TextStyle(color: Colors.grey[500])),
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
                        final userId = docs[index].id;
                        final email = data['email'] ?? 'Sin email';
                        final nombre = data['nombre'] ?? 'Sin nombre';
                        // Check role string instead of boolean
                        final isAdmin = data['role'] == 'admin';
                        final fechaRegistro =
                            data['fechaRegistro'] as Timestamp?;

                        final imagenUrl = data['imagenUrl'] as String?;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: isAdmin
                                ? Colors.purple.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            backgroundImage: (imagenUrl != null &&
                                    imagenUrl.isNotEmpty)
                                ? NetworkImage(_fixGoogleDriveUrl(imagenUrl))
                                : null,
                            child: (imagenUrl == null || imagenUrl.isEmpty)
                                ? Icon(
                                    isAdmin
                                        ? Icons.admin_panel_settings
                                        : Icons.person,
                                    color:
                                        isAdmin ? Colors.purple : Colors.blue,
                                    size: 24,
                                  )
                                : null,
                          ),
                          title: Row(
                            children: [
                              Text(
                                nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              if (isAdmin) ...[
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'ADMIN',
                                    style: TextStyle(
                                      color: Colors.purple,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(email,
                                  style: TextStyle(color: Colors.grey[600])),
                              if (fechaRegistro != null)
                                Text(
                                  'Registrado: ${DateFormat('dd/MM/yyyy').format(fechaRegistro.toDate())}',
                                  style: TextStyle(
                                      color: Colors.grey[400], fontSize: 12),
                                ),
                            ],
                          ),
                          trailing: Switch(
                            value: isAdmin,
                            onChanged: (value) =>
                                _toggleAdminRole(userId, isAdmin, email),
                            activeColor: Colors.purple,
                          ),
                        );
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
}
