import 'package:flutter/material.dart';
import 'pantalla_inicio.dart';
import 'pantalla_carrito.dart';
import 'pantalla_perfil.dart';
import 'main.dart';



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
      // ¡¡CAMBIO AQUÍ!!
      // Le pasamos la nueva función 'onGoToCart' a HomeScreen
      KeepAlivePage(child: HomeScreen(
        onTapCategoria: _onTapCategoria,
        onGoToCart: () => _onItemTapped(1), // <-- 1. Pasa la nueva función
      )),
      KeepAlivePage(child: CartScreen(onExplore: () => _onItemTapped(0))),
      KeepAlivePage(child: PantallaPerfil()),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  void _onTapCategoria(String categoria) {
    // Esta función se llama desde HomeScreen.
  }

  // ¡¡NUEVA FUNCIÓN!! - Muestra el diálogo de confirmación
  Future<void> _showClearCartDialog() async {
     final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(children: [Icon(Icons.delete_sweep, color: Colors.red), SizedBox(width: 8), Text('Vaciar Carrito')]),
        content: const Text('¿Estás seguro de que quieres eliminar todos los productos del carrito?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vaciar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmacion == true) {
      cartNotifier.value = []; // Limpia el carrito
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

  // ¡¡NUEVA FUNCIÓN!! - Decide qué botones mostrar en la AppBar
  List<Widget>? _buildAppBarActions() {
    // Si estamos en la pestaña del Carrito (índice 1) Y el carrito no está vacío...
    if (_selectedIndex == 1 && getCartTotalItemCount() > 0) {
      return [
        IconButton(
          icon: const Icon(Icons.delete_sweep_outlined),
          tooltip: 'Vaciar carrito',
          onPressed: _showClearCartDialog, // Llama a la nueva función
        ),
      ];
    }
    // Si no, no muestra nada
    return null; 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[_selectedIndex]),
        actions: _buildAppBarActions(), 
      ),
      
      body: IndexedStack(
        index: _selectedIndex,
        children: _pantallas,
      ),

      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: cartNotifier,
              builder: (context, cartItems, child) {
                final totalItems = getCartTotalItemCount();
                if (totalItems == 0) {
                  return const Icon(Icons.shopping_cart_outlined);
                }
                return Badge(
                  label: Text(totalItems > 9 ? '9+' : '$totalItems'),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.shopping_cart_outlined),
                );
              },
            ),
            activeIcon: const Icon(Icons.shopping_cart),
            label: 'Carrito',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// (El widget KeepAlivePage no cambia)
class KeepAlivePage extends StatefulWidget {
  const KeepAlivePage({super.key, required this.child});
  final Widget child;
  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}
class _KeepAlivePageState extends State<KeepAlivePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}