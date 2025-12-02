import 'package:flutter/material.dart';
import 'pantalla_inicio.dart';
import 'pantalla_carrito.dart';
import 'pantalla_perfil.dart';
import 'main.dart';
import 'widgets/modern_navbar.dart';
import 'services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int _selectedIndex = 0;

  late final List<Widget> _pantallas;
  final List<String> _titulos = ['Tech Store', 'Mi Carrito', 'Mi Perfil'];

  @override
  void initState() {
    super.initState();
    _pantallas = [
      KeepAlivePage(
          child: HomeScreen(
        onTapCategoria: _onTapCategoria,
        onGoToCart: () => _onItemTapped(1),
      )),
      KeepAlivePage(child: CartScreen(onExplore: () => _onItemTapped(0))),
      KeepAlivePage(child: PantallaPerfil()),
    ];

    // Inicializar notificaciones
    NotificationService().init();
    _setupOrderListener();
  }

  StreamSubscription? _orderSubscription;

  void _setupOrderListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _orderSubscription = FirebaseFirestore.instance
        .collection('Pedidos')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data() as Map<String, dynamic>;
          final nuevoEstado = data['estado'];
          final pedidoId = data['pedidoId'] ?? 'Desconocido';

          // Mostrar notificación
          NotificationService().showNotification(
            id: pedidoId.hashCode,
            title: 'Actualización de Pedido',
            body: 'Tu pedido #$pedidoId ahora está: $nuevoEstado',
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onTapCategoria(String categoria) {
    // Esta función se llama desde HomeScreen.
  }

  Future<void> _showClearCartDialog() async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.delete_sweep, color: Colors.red),
          SizedBox(width: 8),
          Text('Vaciar Carrito')
        ]),
        content: const Text(
            '¿Estás seguro de que quieres eliminar todos los productos del carrito?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vaciar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmacion == true) {
      cartNotifier.value = [];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Carrito vaciado'),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<Widget>? _buildAppBarActions() {
    if (_selectedIndex == 1 && getCartTotalItemCount() > 0) {
      return [
        IconButton(
          icon: const Icon(Icons.delete_sweep_outlined),
          tooltip: 'Vaciar carrito',
          onPressed: _showClearCartDialog,
        ),
      ];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(_titulos[_selectedIndex]),
        actions: _buildAppBarActions(),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pantallas,
      ),
      bottomNavigationBar: ModernNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
      ),
    );
  }
}

class KeepAlivePage extends StatefulWidget {
  const KeepAlivePage({super.key, required this.child});
  final Widget child;
  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
