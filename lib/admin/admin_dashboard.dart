// admin_dashboard.dart - VERSIÓN MEJORADA
import 'package:flutter_admin_scaffold/admin_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_home.dart';
import 'admin_pedidos.dart';
import 'admin_productos.dart';
import 'admin_login.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Widget _selectedScreen = const AdminHomeScreen();
  String _selectedRoute = AdminHomeScreen.routeName;

  void _navigateTo(String route) {
    setState(() {
      _selectedRoute = route;
      if (route == AdminHomeScreen.routeName) {
        _selectedScreen = const AdminHomeScreen();
      } else if (route == AdminPedidosScreen.routeName) {
        _selectedScreen = const AdminPedidosScreen();
      } else if (route == AdminProductosScreen.routeName) {
        _selectedScreen = const AdminProductosScreen();
      }
    });
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const AdminLoginPage()),
                );
              }
            },
            child: const Text('Salir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.white),
            SizedBox(width: 8),
            Text('Panel de Administración'),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'Notificaciones',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: _logout,
          ),
        ],
      ),
      sideBar: SideBar(
        backgroundColor: const Color(0xFF1e1b2e),
        activeBackgroundColor: Colors.deepPurple.shade600,
        borderColor: Colors.transparent,
        iconColor: Colors.white70,
        activeIconColor: Colors.white,
        textStyle: const TextStyle(color: Colors.white70, fontSize: 14),
        activeTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        items: const [
          AdminMenuItem(
            title: 'Dashboard',
            icon: Icons.dashboard,
            route: AdminHomeScreen.routeName,
          ),
          AdminMenuItem(
            title: 'Gestión de Pedidos',
            icon: Icons.shopping_cart_checkout,
            route: AdminPedidosScreen.routeName,
          ),
          AdminMenuItem(
            title: 'Gestión de Productos',
            icon: Icons.inventory_2,
            route: AdminProductosScreen.routeName,
          ),
        ],
        selectedRoute: _selectedRoute,
        onSelected: (item) {
          if (item.route != null) {
            _navigateTo(item.route!);
          }
        },
        header: Container(
          height: 120,
          width: double.infinity,
          color: const Color(0xFF151321),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                const Text(
                  'TechStore',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Administración',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        footer: Container(
          height: 60,
          width: double.infinity,
          color: const Color(0xFF151321),
          child: Center(
            child: ListTile(
              leading: const Icon(Icons.person, color: Colors.white70, size: 20),
              title: Text(
                FirebaseAuth.instance.currentUser?.email ?? 'Admin',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.logout, color: Colors.white70, size: 16),
                onPressed: _logout,
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade50,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: _selectedScreen,
      ),
    );
  }
}