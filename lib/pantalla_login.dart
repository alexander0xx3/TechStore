import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  // Controladores y Claves
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  // Estado de la UI
  bool _cargando = false;
  bool _obscureText = true;

  // --- LÓGICA DE AUTENTICACIÓN ---

  Future<void> _iniciarSesionConGoogle() async {
    setState(() => _cargando = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _cargando = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Verificar si el usuario ya existe en Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          // Si no existe, crearlo
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .set({
            'nombre': user.displayName ?? 'Usuario de Google',
            'email': user.email ?? '',
            'role': 'user', // Rol por defecto
            'fechaRegistro': FieldValue.serverTimestamp(),
            'telefono': user.phoneNumber ?? '',
            'direccion': '',
            'imagenUrl': user.photoURL ?? '',
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Bienvenido, ${googleUser.displayName ?? ''}!'),
            backgroundColor: Colors.green[700],
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _mostrarError(
            context, 'Error de Google Sign-In', e.toString(), null, null);
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Bienvenido de nuevo!'),
            backgroundColor: Colors.green[700],
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Ocurrió un error. Inténtalo de nuevo.';
      String? detalle;
      String? accion;
      VoidCallback? onAccion;

      if (e.code == 'user-not-found') {
        mensaje = 'No se encontró una cuenta con ese email.';
        detalle = '¿Quieres crear una nueva cuenta?';
        accion = 'Registrarse';
        onAccion = () => Navigator.pushReplacementNamed(context, '/register');
      } else if (e.code == 'wrong-password') {
        mensaje = 'Contraseña incorrecta.';
        detalle = 'Verifica tu contraseña e intenta nuevamente.';
      } else {
        mensaje = e.message ?? 'Error desconocido.';
      }

      if (mounted) {
        _mostrarError(context, mensaje, detalle, accion, onAccion);
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // --- MÉTODOS DE DIÁLOGO Y ERROR ---

  void _mostrarError(BuildContext context, String mensaje, String? detalle,
      String? accion, VoidCallback? onAccion) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mensaje, style: const TextStyle(fontWeight: FontWeight.w500)),
            if (detalle != null) ...[
              const SizedBox(height: 4),
              Text(detalle, style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
        backgroundColor: Colors.red[800],
        duration: const Duration(seconds: 5),
        action: accion != null && onAccion != null
            ? SnackBarAction(label: accion, onPressed: onAccion)
            : null,
      ),
    );
  }

  Future<void> _mostrarRecuperarPassword() async {
    final email = _emailController.text.trim();
    final controller = TextEditingController(text: email);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar Contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Ingresa tu email para enviar un enlace de recuperación:'),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                  labelText: 'Email', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              try {
                await _auth.sendPasswordResetEmail(
                    email: controller.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Email de recuperación enviado a ${controller.text.trim()}'),
                      backgroundColor: Colors.green[700],
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  _mostrarError(context, 'Error al enviar email', e.toString(),
                      null, null);
                }
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- UI BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.grey[50]!,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tarjeta de Bienvenida
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.storefront,
                          size: 80,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bienvenido a TechStore',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ingresa a tu cuenta para continuar',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Campo email
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(
                        color: Colors.black87), // Fix text color
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.grey[700]),
                      hintText: 'tu@email.com',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon:
                          const Icon(Icons.email_outlined, color: Colors.grey),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, ingresa tu email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value.trim())) {
                        return 'Por favor, ingresa un email válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    style: const TextStyle(
                        color: Colors.black87), // Fix text color
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      labelStyle: TextStyle(color: Colors.grey[700]),
                      prefixIcon:
                          const Icon(Icons.lock_outline, color: Colors.grey),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingresa tu contraseña';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Botón Olvidaste contraseña
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _cargando ? null : _mostrarRecuperarPassword,
                      child: Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón de inicio de sesión
                  ElevatedButton(
                    onPressed: _cargando ? null : _iniciarSesion,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: _cargando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 3))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login, size: 20),
                              SizedBox(width: 8),
                              Text('Iniciar Sesión'),
                            ],
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Botón de Google
                  OutlinedButton(
                    onPressed: _cargando ? null : _iniciarSesionConGoogle,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: Colors.grey[800],
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey[400]!),
                      backgroundColor: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.network(
                          'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                          height: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text('Continuar con Google'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Divisor
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: Colors.grey[400]),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '¿No tienes cuenta?',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Colors.grey[400]),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Botón de registro
                  OutlinedButton(
                    onPressed: _cargando
                        ? null
                        : () {
                            Navigator.pushReplacementNamed(
                                context, '/register');
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Theme.of(context).primaryColor,
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Crear Cuenta Nueva'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
