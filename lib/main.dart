import 'package:flutter/foundation.dart' show kIsWeb; // ¡NUEVO! Para detectar web
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // ¡NUEVO! Generado por 'flutterfire configure'

// --- Importaciones de tu App Móvil (ya las tienes) ---
import 'PantallaPrincipal.dart'; 
import 'pantalla_carrito.dart';
import 'pantalla_login.dart';
import 'pantalla_registro.dart';
import "pantalla_perfil.dart";
import 'pantalla_pedidos.dart'; 
import 'pantalla_direcciones.dart'; 
import 'pantalla_deseos.dart'; 

// --- ¡NUEVA IMPORTACIÓN! Para el Panel de Admin ---
// (Asegúrate de que el nombre del archivo sea 'admin_login.dart')
import 'admin/admin_login.dart'; 

// --- Lógica global del carrito (Tu código original) ---
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
  
 
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const TechStoreApp());
}

class TechStoreApp extends StatelessWidget {
  const TechStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tech Store',
      debugShowCheckedModeBanner: false,
      
      // --- ¡MODIFICADO! (Primario 'indigo' como en tu guía) ---
      theme: ThemeData(
        primarySwatch: Colors.indigo, // Color principal para el admin
        primaryColor: Colors.indigo[900], // Tono más oscuro
        scaffoldBackgroundColor: Colors.grey[100], 
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.indigo[900], 
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
          selectedColor: Colors.indigo[800],
          secondarySelectedColor: Colors.indigo[800],
          labelStyle: const TextStyle(color: Colors.black),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          shape: const StadiumBorder(),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.indigo[900], 
          unselectedItemColor: Colors.grey[600], 
          backgroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo[800],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      
  
      home: kIsWeb 
          ? const AdminLoginPage()      // Si es WEB, muestra el Login de Admin
          : const PantallaPrincipal(), // Si es MÓVIL, muestra tu tienda
      
      // Tus rutas de la app móvil (sin cambios)
      routes: {
        '/cart': (context) => const CartScreen(),
        '/login': (context) => const PantallaLogin(),
        '/register': (context) => const PantallaRegistro(),
        '/profile': (context) => const PantallaPerfil(),
        '/orders': (context) => const PantallaPedidos(), 
        '/direcciones': (context) => const PantallaDirecciones(),
        '/wishlist': (context) => const PantallaDeseos(),
      },
    );
  }
}