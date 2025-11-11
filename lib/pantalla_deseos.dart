// pantalla_wishlist.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart'; // Importamos la lógica del carrito

class PantallaDeseos extends StatefulWidget { 
  const PantallaDeseos({super.key});

  @override
  State<PantallaDeseos> createState() => _PantallaDeseosState();
}

class _PantallaDeseosState extends State<PantallaDeseos> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
  }

  // --- Funciones de Acciones ---

  // Mueve el producto de la wishlist al carrito
  Future<void> _moveToCart(Map<String, dynamic> productData, String docId) async {
    // 1. Añade al carrito (usando la función global de main.dart)
    addProductToCart(productData);

    // 2. Elimina de la wishlist
    await _removeFromWishlist(docId);

    // 3. Muestra notificación
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${productData['nombre']} añadido al carrito'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Solo elimina el producto de la wishlist
  Future<void> _removeFromWishlist(String docId) async {
    if (_currentUser == null) return;
    try {
      await _firestore
          .collection('Usuarios')
          .doc(_currentUser!.uid)
          .collection('Wishlist')
          .doc(docId)
          .delete();
      
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Producto eliminado de tu lista'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Manejar error si es necesario
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Lista de Deseos'),
      ),
      body: _currentUser == null
          ? _buildLoginPrompt()
          : _buildWishlistStream(),
    );
  }

  // --- Widgets de Construcción ---

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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
               Text(
                'Para ver tu lista de deseos, por favor inicia sesión.',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.account_circle),
                label: const Text('Ir a Iniciar Sesión'),
                onPressed: () {
                   Navigator.pushNamed(context, '/login').then((_) {
                      setState(() { _currentUser = _auth.currentUser; });
                   }); 
                },
              )
           ],
         ),
       ),
     );
  }

  Widget _buildWishlistStream() {
    return StreamBuilder<QuerySnapshot>(
      // Consulta a la sub-colección del usuario
      stream: _firestore
          .collection('Usuarios')
          .doc(_currentUser!.uid)
          .collection('Wishlist')
          .orderBy('savedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar productos: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final productDocs = snapshot.data!.docs;
        
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: productDocs.length,
          itemBuilder: (context, index) {
            return _buildWishlistItem(productDocs[index]); 
          },
        );
      },
    );
  }

  // Widget para CADA item de la lista
  Widget _buildWishlistItem(QueryDocumentSnapshot doc) {
     final productData = doc.data() as Map<String, dynamic>;
     final docId = doc.id; // Este es el ID del producto

     final nombre = productData['nombre'] ?? 'Sin nombre';
     final precio = (productData['precio'] as num? ?? 0.0).toDouble();
     final imagenUrl = productData['imagen'] ?? '';

     return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imagenUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(width: 80, height: 80, color: Colors.grey[200], child: Icon(Icons.broken_image, color: Colors.grey[400])),
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'S/ ${precio.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600, 
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Botones de Acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botón Eliminar
                TextButton.icon(
                  icon: Icon(Icons.delete_outline, color: Colors.red[700], size: 20),
                  label: Text('Eliminar', style: TextStyle(color: Colors.red[700])),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => _removeFromWishlist(docId),
                ),
                // Botón Mover al Carrito
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('Mover al Carrito'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () => _moveToCart(productData, docId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget para mostrar cuando no hay productos
  Widget _buildEmptyState() {
     return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              'Tu lista de deseos está vacía',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              'Guarda productos desde el carrito para verlos aquí más tarde.',
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}