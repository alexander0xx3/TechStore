import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'providers/theme_provider.dart';

class PantallaPerfil extends StatefulWidget {
  const PantallaPerfil({super.key});

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  final _auth = FirebaseAuth.instance;
  User? _usuario;
  bool _cargando = true;
  bool _subiendoImagen = false; // Estado para mostrar carga al subir imagen

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

  // --- Lógica de Cámara / Galería ---
  Future<void> _cambiarFotoPerfil() async {
    final ImagePicker picker = ImagePicker();

    // Mostrar diálogo para elegir fuente
    final XFile? image = await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Tomar foto'),
                onTap: () async {
                  final image =
                      await picker.pickImage(source: ImageSource.camera);
                  if (!context.mounted) return;
                  Navigator.pop(context, image);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Elegir de galería'),
                onTap: () async {
                  final image =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (!context.mounted) return;
                  Navigator.pop(context, image);
                },
              ),
            ],
          ),
        );
      },
    );

    if (image != null && _usuario != null) {
      setState(() => _subiendoImagen = true);
      try {
        final File file = File(image.path);
        final String fileName = 'user_profiles/${_usuario!.uid}.jpg';

        // Subir a Firebase Storage
        final Reference ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(file);
        final String downloadUrl = await ref.getDownloadURL();

        // Actualizar perfil de usuario
        await _usuario!.updatePhotoURL(downloadUrl);
        await _usuario!.reload();

        // Actualizar estado local
        setState(() {
          _usuario = _auth.currentUser;
          _subiendoImagen = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Foto de perfil actualizada'),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        setState(() => _subiendoImagen = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al subir imagen: $e'),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
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
        title: const Row(children: [
          Icon(Icons.logout, color: Colors.red),
          SizedBox(width: 8),
          Text('Cerrar Sesión')
        ]),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar Sesión',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- Widgets de Diseño Premium ---

  Widget _buildHeader() {
    // final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Fondo con gradiente y curva
        Container(
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),
        // Información del usuario
        Positioned(
          top: 60,
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _usuario?.photoURL != null
                          ? NetworkImage(_usuario!.photoURL!)
                          : null,
                      child: _subiendoImagen
                          ? const CircularProgressIndicator()
                          : (_usuario?.photoURL == null
                              ? Icon(Icons.person,
                                  size: 50, color: Colors.grey[400])
                              : null),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _cambiarFotoPerfil,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _usuario?.displayName ?? 'Usuario',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _usuario?.email ?? 'email@ejemplo.com',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.titleLarge?.color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
    Widget? trailing,
    Color? iconColor,
  }) {
    // final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20))
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (iconColor ?? Theme.of(context).primaryColor)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? Theme.of(context).primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailing != null)
                trailing
              else
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 70,
      endIndent: 20,
      color: Theme.of(context).dividerColor.withOpacity(0.5),
    );
  }

  Widget _buildThemeToggle() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return _buildMenuItem(
      icon: themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
      title: "Modo Oscuro",
      iconColor: Colors.purple,
      onTap: () => themeProvider.toggleTheme(),
      trailing: Switch.adaptive(
        value: themeProvider.isDarkMode,
        onChanged: (value) => themeProvider.toggleTheme(),
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_circle_outlined,
                size: 100, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              'Inicia sesión',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Accede a tu perfil, historial de pedidos y más.',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Iniciar Sesión / Registrarse',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_usuario == null) {
      return _buildLoginPrompt(context);
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 10), // Espacio para solapar si quisiéramos
            AnimationLimiter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 375),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: widget,
                    ),
                  ),
                  children: [
                    // --- MI CUENTA ---
                    _buildSectionTitle("Mi Cuenta"),
                    _buildMenuCard([
                      _buildMenuItem(
                        icon: Icons.shopping_bag_outlined,
                        title: "Mis Pedidos",
                        onTap: () => Navigator.pushNamed(context, '/orders'),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.favorite_border_rounded,
                        title: "Lista de Deseos",
                        iconColor: Colors.pink,
                        onTap: () => Navigator.pushNamed(context, '/wishlist'),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.location_on_outlined,
                        title: "Direcciones",
                        iconColor: Colors.orange,
                        onTap: () =>
                            Navigator.pushNamed(context, '/direcciones'),
                        isLast: true,
                      ),
                    ]),

                    // --- CONFIGURACIÓN ---
                    _buildSectionTitle("Configuración"),
                    _buildMenuCard([
                      _buildThemeToggle(),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.notifications_none_rounded,
                        title: "Notificaciones",
                        iconColor: Colors.blue,
                        onTap: () {},
                        trailing: Switch.adaptive(
                          value: true,
                          onChanged: (val) {},
                          activeColor: Theme.of(context).primaryColor,
                        ),
                        isLast: true,
                      ),
                    ]),

                    // --- AYUDA ---
                    _buildSectionTitle("Ayuda"),
                    _buildMenuCard([
                      _buildMenuItem(
                        icon: Icons.history_edu,
                        title: "Historial de Soporte",
                        iconColor: Colors.deepPurple,
                        onTap: () =>
                            Navigator.pushNamed(context, '/soporte_historial'),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.headset_mic_outlined,
                        title: "Soporte Técnico",
                        iconColor: Colors.teal,
                        onTap: () => Navigator.pushNamed(
                            context, '/soporte'), // Navegar a Soporte
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.info_outline_rounded,
                        title: "Términos y Condiciones",
                        iconColor: Colors.grey,
                        onTap: () {},
                        isLast: true,
                      ),
                    ]),

                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Cerrar Sesión'),
                        onPressed: _cerrarSesion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          foregroundColor: Colors.red,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
