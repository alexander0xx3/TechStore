// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'PantallaPrincipal.dart'; 
import 'pantalla_carrito.dart';
import 'pantalla_login.dart';
import 'pantalla_registro.dart';
import "pantalla_perfil.dart";
import 'pantalla_pedidos.dart'; 
import 'pantalla_direcciones.dart'; 
import 'pantalla_deseos.dart'; // ¡¡NUEVO IMPORT!!



// --- Lógica global del carrito (sin cambios) ---
final ValueNotifier<List<Map<String, dynamic>>> cartNotifier = ValueNotifier([]);

void addProductToCart(Map<String, dynamic> product) {
  final current = List<Map<String, dynamic>>.from(cartNotifier.value);
  final index = current.indexWhere((item) => item['id'] == product['id']);
  if (index != -1) {
    current[index]['quantity'] = (current[index]['quantity'] ?? 1) + 1;
  } else {
    product['quantity'] = 1;
    current.add(product);
  }
  cartNotifier.value = current;
}

void removeProductFromCart(Map<String, dynamic> product) {
  final current = List<Map<String, dynamic>>.from(cartNotifier.value);
  final index = current.indexWhere((item) => item['id'] == product['id']);
  if (index != -1) {
    if ((current[index]['quantity'] ?? 1) > 1) {
      current[index]['quantity']--;
    } else {
      current.removeAt(index);
    }
    cartNotifier.value = current;
  }
}

double getCartTotalPrice() {
  var total = 0.0;
  for (var item in cartNotifier.value) {
    total += ( (item['precio'] as num? ?? 0.0) * (item['quantity'] as num? ?? 1) );
  }
  return total;
}

int getCartTotalItemCount() {
  var count = 0;
  for (var item in cartNotifier.value) {
    count += ( (item['quantity'] as num? ?? 1) ).toInt();
  }
  return count;
}
// --- Fin Lógica global del carrito ---


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const TechStoreApp());
}

class TechStoreApp extends StatelessWidget {
  const TechStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tech Store',
      debugShowCheckedModeBanner: false,
      
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        primaryColor: Colors.blueGrey[900],
        scaffoldBackgroundColor: Colors.grey[100], 
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blueGrey[900], 
          foregroundColor: Colors.white, 
          elevation: 1,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias, 
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.lightBlueAccent[400],
          foregroundColor: Colors.white,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.grey[200],
          selectedColor: Colors.blueGrey[800],
          secondarySelectedColor: Colors.blueGrey[800],
          labelStyle: const TextStyle(color: Colors.black),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          shape: const StadiumBorder(),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.blueGrey[900], 
          unselectedItemColor: Colors.grey[600], 
          backgroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey[800],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      
      home: const PantallaPrincipal(),
      
      routes: {
        '/cart': (context) => const CartScreen(),
        '/login': (context) => const PantallaLogin(),
        '/register': (context) => const PantallaRegistro(),
        '/profile': (context) => const PantallaPerfil(),
        '/orders': (context) => const PantallaPedidos(), 
        '/direcciones': (context) => const PantallaDirecciones(),
        '/wishlist': (context) => const PantallaDeseos(), // ¡¡NUEVA RUTA!!
      },
    );
  }
}