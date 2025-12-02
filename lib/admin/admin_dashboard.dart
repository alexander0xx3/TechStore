import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_home.dart';
import 'admin_pedidos.dart';
import 'admin_productos.dart';
import 'admin_login.dart';
import 'admin_soporte.dart';
import 'admin_usuarios.dart';

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
      switch (route) {
        case AdminHomeScreen.routeName:
          _selectedScreen = const AdminHomeScreen();
          break;
        case AdminPedidosScreen.routeName:
          _selectedScreen = const AdminPedidosScreen();
          break;
        case AdminProductosScreen.routeName:
          _selectedScreen = const AdminProductosScreen();
          break;
        case AdminSoporteScreen.routeName:
          _selectedScreen = const AdminSoporteScreen();
          break;
        case AdminUsuariosScreen.routeName:
          _selectedScreen = const AdminUsuariosScreen();
          break;
      }
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos LayoutBuilder para responsive si es necesario,
    // pero por ahora mantenemos la estructura Row para web desktop.
    return Scaffold(
      backgroundColor: Colors.grey[50], // Fondo general claro
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white, // Sidebar blanca
              border: Border(
                right: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Column(
              children: [
                // Logo Area
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB), // Azul primario
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.store,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'TechStore',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Menu Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildMenuItem(
                        title: 'Dashboard',
                        route: AdminHomeScreen.routeName,
                        icon: Icons.dashboard_outlined,
                        selectedIcon: Icons.dashboard,
                      ),
                      const SizedBox(height: 4),
                      _buildMenuItem(
                        title: 'Productos',
                        route: AdminProductosScreen.routeName,
                        icon: Icons.inventory_2_outlined,
                        selectedIcon: Icons.inventory_2,
                      ),
                      const SizedBox(height: 4),
                      _buildMenuItem(
                        title: 'Pedidos',
                        route: AdminPedidosScreen.routeName,
                        icon: Icons.shopping_bag_outlined,
                        selectedIcon: Icons.shopping_bag,
                      ),
                      const SizedBox(height: 4),
                      _buildMenuItem(
                        title: 'Usuarios',
                        route: AdminUsuariosScreen.routeName,
                        icon: Icons.people_outline,
                        selectedIcon: Icons.people,
                      ),
                      const SizedBox(height: 4),
                      _buildMenuItem(
                        title: 'Soporte',
                        route: AdminSoporteScreen.routeName,
                        icon: Icons.support_agent_outlined,
                        selectedIcon: Icons.support_agent,
                      ),
                    ],
                  ),
                ),

                // User Profile / Logout
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[100]!),
                    ),
                  ),
                  child: InkWell(
                    onTap: _logout,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.logout,
                              color: Colors.redAccent, size: 20),
                          const SizedBox(width: 12),
                          const Text(
                            'Cerrar Sesión',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // MAIN CONTENT
          Expanded(
            child: Container(
              color: Colors.grey[50], // Fondo del contenido
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: KeyedSubtree(
                  key: ValueKey(_selectedRoute),
                  child: _selectedScreen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required String route,
    required IconData icon,
    required IconData selectedIcon,
  }) {
    final isSelected = _selectedRoute == route;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateTo(route),
        borderRadius: BorderRadius.circular(12),
        hoverColor: Colors.grey[50],
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFEFF6FF)
                : Colors.transparent, // Azul muy claro
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                size: 22,
                color: isSelected ? const Color(0xFF2563EB) : Colors.grey[500],
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color:
                      isSelected ? const Color(0xFF2563EB) : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
