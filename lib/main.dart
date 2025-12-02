import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

import 'PantallaPrincipal.dart';
import 'pantalla_carrito.dart';
import 'pantalla_login.dart';
import 'pantalla_registro.dart';
import "pantalla_perfil.dart";
import 'pantalla_pedidos.dart';
import 'pantalla_direcciones.dart';
import 'pantalla_deseos.dart';
import 'admin/admin_login.dart';
import 'providers/theme_provider.dart';
import 'pantalla_soporte.dart';
import 'pantalla_historial_soporte.dart';

// --- Lógica global del carrito ---
final ValueNotifier<List<Map<String, dynamic>>> cartNotifier =
    ValueNotifier([]);

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
    total +=
        ((item['precio'] as num? ?? 0.0) * (item['quantity'] as num? ?? 1));
  }
  return total;
}

int getCartTotalItemCount() {
  var count = 0;
  for (var item in cartNotifier.value) {
    count += ((item['quantity'] as num? ?? 1)).toInt();
  }
  return count;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    debugPrint('Firebase initialization error (likely duplicate): $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const TechStoreApp(),
    ),
  );
}

class TechStoreApp extends StatelessWidget {
  const TechStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Tech Store',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,

      // Tema Claro - Azul-Morado
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          primary: const Color(0xFF1A237E),
          secondary: const Color(0xFF6A1B9A),
          tertiary: const Color(0xFF00BCD4),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF1A237E),
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          color: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF00BCD4),
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.grey[200],
          selectedColor: const Color(0xFF6A1B9A),
          secondarySelectedColor: const Color(0xFF6A1B9A),
          labelStyle: const TextStyle(color: Colors.black87),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          shape: const StadiumBorder(),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6A1B9A),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),

      // Tema Oscuro - Azul-Morado Mejorado
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9C27B0),
          primary: const Color(0xFF9C27B0),
          secondary: const Color(0xFF1A237E),
          tertiary: const Color(0xFF00BCD4),
          brightness: Brightness.dark,
          surface: const Color(0xFF1A1F3A),
          background: const Color(0xFF0A0E27),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0E27),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF1A237E),
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          color: const Color(0xFF1A1F3A),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF00BCD4),
          foregroundColor: Colors.white,
          elevation: 6,
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: Color(0xFF1A1F3A),
          selectedColor: Color(0xFF9C27B0),
          secondarySelectedColor: Color(0xFF9C27B0),
          labelStyle: TextStyle(color: Colors.white70),
          secondaryLabelStyle: TextStyle(color: Colors.white),
          shape: StadiumBorder(),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9C27B0),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        // Mejorar contraste de texto
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          bodySmall: TextStyle(color: Colors.white60),
          titleLarge:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white70),
        ),
        // Mejorar SnackBar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF1A1F3A),
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          behavior: SnackBarBehavior.floating,
        ),
        // Mejorar Dialog
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF1A1F3A),
          titleTextStyle: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          contentTextStyle:
              const TextStyle(color: Colors.white70, fontSize: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),

      home: kIsWeb ? const AdminLoginScreen() : const PantallaPrincipal(),

      routes: {
        '/cart': (context) => const CartScreen(),
        '/login': (context) => const PantallaLogin(),
        '/register': (context) => const PantallaRegistro(),
        '/profile': (context) => const PantallaPerfil(),
        '/orders': (context) => const PantallaPedidos(),
        '/direcciones': (context) => const PantallaDirecciones(),
        '/wishlist': (context) => const PantallaDeseos(),
        '/soporte': (context) => const PantallaSoporte(),
        '/soporte_historial': (context) => const PantallaHistorialSoporte(),
      },
    );
  }
}
