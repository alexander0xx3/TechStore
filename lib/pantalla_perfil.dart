// pantalla_perfil.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PantallaPerfil extends StatefulWidget {
  const PantallaPerfil({super.key});

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  final _auth = FirebaseAuth.instance;
  User? _usuario;
  bool _cargando = true; // Inicia cargando

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    _auth.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _usuario = user;
          _cargando = false;
        });
      }
    });
  }

  Future<void> _cerrarSesion() async {
    final confirmacion = await _mostrarDialogoConfirmacion(context);
    if (confirmacion == true) {
      try {
        await _auth.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Sesión cerrada correctamente'),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cerrar sesión: $e'),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<bool?> _mostrarDialogoConfirmacion(BuildContext context) async {
     return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(children: [Icon(Icons.logout, color: Colors.red), SizedBox(width: 8), Text('Cerrar Sesión')]),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- Widgets de Construcción ---

  Widget _buildHeader() {
     return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor, // Color del tema
            Theme.of(context).primaryColorDark,
          ],
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  color: Colors.white.withOpacity(0.2),
                ),
                child: ClipOval(
                  child: _usuario?.photoURL != null
                      ? Image.network(
                          _usuario!.photoURL!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 40),
                        )
                      : Icon(Icons.person, color: Colors.white.withOpacity(0.8), size: 40),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(Icons.edit, color: Theme.of(context).primaryColor, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _usuario?.displayName ?? 'Usuario',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
           Text(
            _usuario?.email ?? 'email@ejemplo.com',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
          ),
          if (_usuario != null && !_usuario!.emailVerified)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Chip(
                label: const Text('Email no verificado'),
                backgroundColor: Colors.orange[100],
                labelStyle: TextStyle(color: Colors.orange[800], fontSize: 10, fontWeight: FontWeight.w500),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupedMenuCard({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor, size: 22),
                const SizedBox(width: 16),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
          if (showDivider)
            Divider(height: 1, thickness: 1, indent: 54, color: Colors.grey[200]),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
     return const Center(child: CircularProgressIndicator());
  }
  
  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login_rounded, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text('Inicia sesión', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text('Para ver tu perfil, inicia sesión o crea una cuenta.', style: TextStyle(color: Colors.grey[600], fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.account_circle),
              label: const Text('Ir a Iniciar Sesión'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                 Navigator.pushNamed(context, '/login'); 
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return _buildLoadingState();
    }
    
    if (_usuario == null) {
      return _buildLoginPrompt(context);
    }
    
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(), 
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                
                _buildGroupedMenuCard(
                  title: "Mi Cuenta",
                  children: [
                    _buildMenuRow(
                      icon: Icons.receipt_long,
                      title: "Mis Pedidos",
                      onTap: () { Navigator.pushNamed(context, '/orders'); },
                    ),
                    
                    // --- ¡¡NUEVO BOTÓN!! ---
                    _buildMenuRow(
                      icon: Icons.bookmark_border_rounded, // Icono de Wishlist
                      title: "Mi Lista de Deseos",
                      onTap: () { Navigator.pushNamed(context, '/wishlist'); },
                    ),
                    // --- FIN NUEVO BOTÓN ---

                    _buildMenuRow(
                      icon: Icons.location_on_outlined,
                      title: "Direcciones de Envío",
                      onTap: () { Navigator.pushNamed(context, '/direcciones'); },
                    ),
                    _buildMenuRow(
                      icon: Icons.payment_outlined,
                      title: "Métodos de Pago",
                      onTap: () { /* Acción Pagos */ },
                      showDivider: false,
                    ),
                  ],
                ),
                
                _buildGroupedMenuCard(
                  title: "Información y Ayuda",
                  children: [
                     _buildMenuRow(
                      icon: Icons.support_agent,
                      title: "Soporte Técnico",
                      onTap: () {},
                    ),
                    _buildMenuRow(
                      icon: Icons.policy_outlined,
                      title: "Términos y Condiciones",
                      onTap: () {},
                      showDivider: false,
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                ElevatedButton.icon(
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text('Cerrar Sesión'),
                  onPressed: _cerrarSesion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}