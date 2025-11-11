import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool _cargando = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _terminosAceptados = false;

  // Validación de fortaleza de contraseña
  String? _validarFortalezaPassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa una contraseña';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    
    final hasUpperCase = RegExp(r'[A-Z]').hasMatch(value);
    final hasLowerCase = RegExp(r'[a-z]').hasMatch(value);
    final hasNumbers = RegExp(r'[0-9]').hasMatch(value);
    final hasSpecialChars = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);
    
    int strength = 0;
    if (hasUpperCase) strength++;
    if (hasLowerCase) strength++;
    if (hasNumbers) strength++;
    if (hasSpecialChars) strength++;
    
    if (strength < 2) {
      return 'Usa mayúsculas, números o símbolos';
    }
    
    return null;
  }

  Future<void> _registrarse() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_terminosAceptados) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Debes aceptar los términos y condiciones'),
          backgroundColor: Colors.orange[800],
        ),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(_nombreController.text.trim());
        await userCredential.user!.sendEmailVerification();
        await userCredential.user!.reload(); 
      }

      if (mounted) {
        // Mostrar diálogo de éxito
        await _mostrarDialogoExito(context);
        Navigator.pop(context);
      }

    } on FirebaseAuthException catch (e) {
      String mensaje = 'Ocurrió un error. Inténtalo de nuevo.';
      String? detalle;
      
      if (e.code == 'weak-password') {
        mensaje = 'La contraseña es muy débil.';
        detalle = 'Usa una combinación de letras, números y símbolos.';
      } else if (e.code == 'email-already-in-use') {
        mensaje = 'Ya existe una cuenta con ese email.';
        detalle = '¿Ya tienes cuenta? Inicia sesión.';
      } else if (e.code == 'invalid-email') {
        mensaje = 'El formato del email no es válido.';
        detalle = 'Verifica que el email esté escrito correctamente.';
      } else if (e.code == 'operation-not-allowed') {
        mensaje = 'Operación no permitida.';
        detalle = 'Contacta con soporte técnico.';
      }
      
      if (mounted) {
        _mostrarError(context, mensaje, detalle);
      }
    } catch (e) {
      if (mounted) {
        _mostrarError(context, 'Error inesperado', e.toString());
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _mostrarDialogoExito(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('¡Registro Exitoso!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tu cuenta ha sido creada exitosamente.'),
            const SizedBox(height: 8),
            Text(
              'Hemos enviado un email de verificación a ${_emailController.text.trim()}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  void _mostrarError(BuildContext context, String mensaje, String? detalle) {
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
        action: detalle?.contains('Inicia sesión') == true
            ? SnackBarAction(
                label: 'Iniciar Sesión',
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
              )
            : null,
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator(String password) {
    if (password.isEmpty) return const SizedBox();
    
    final hasMinLength = password.length >= 6;
    final hasUpperCase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowerCase = RegExp(r'[a-z]').hasMatch(password);
    final hasNumbers = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialChars = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    
    int strength = 0;
    if (hasUpperCase) strength++;
    if (hasLowerCase) strength++;
    if (hasNumbers) strength++;
    if (hasSpecialChars) strength++;
    if (hasMinLength) strength++;
    
    Color color = Colors.red;
    String text = 'Muy débil';
    double width = 0.2;
    
    if (strength >= 3) {
      color = Colors.orange;
      text = 'Moderada';
      width = 0.5;
    }
    if (strength >= 4) {
      color = Colors.lightGreen;
      text = 'Buena';
      width = 0.75;
    }
    if (strength >= 5) {
      color = Colors.green;
      text = 'Excelente';
      width = 1.0;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: width,
                backgroundColor: Colors.grey[300],
                color: color,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          children: [
            _buildRequirementIndicator('6+ chars', hasMinLength),
            _buildRequirementIndicator('A-Z', hasUpperCase),
            _buildRequirementIndicator('a-z', hasLowerCase),
            _buildRequirementIndicator('0-9', hasNumbers),
            _buildRequirementIndicator('@#\$', hasSpecialChars),
          ],
        ),
      ],
    );
  }

  Widget _buildRequirementIndicator(String text, bool fulfilled) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          fulfilled ? Icons.check_circle : Icons.radio_button_unchecked,
          color: fulfilled ? Colors.green : Colors.grey,
          size: 12,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: fulfilled ? Colors.green : Colors.grey,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
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
                  // Logo y título
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
                          'Únete a TechStore',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crea tu cuenta para comenzar a comprar',
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

                  // Campo nombre completo
                  TextFormField(
                    controller: _nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre Completo',
                      hintText: 'Juan Pérez',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.name,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, ingresa tu nombre';
                      }
                      if (value.trim().length < 2) {
                        return 'El nombre debe tener al menos 2 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo email
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'tu@email.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, ingresa tu email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                        return 'Por favor, ingresa un email válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                    validator: _validarFortalezaPassword,
                  ),
                  _buildPasswordStrengthIndicator(_passwordController.text),
                  const SizedBox(height: 16),

                  // Campo confirmar contraseña
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, confirma tu contraseña';
                      }
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Checkbox términos y condiciones
                  Row(
                    children: [
                      Checkbox(
                        value: _terminosAceptados,
                        onChanged: (value) {
                          setState(() {
                            _terminosAceptados = value ?? false;
                          });
                        },
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      Expanded(
                        child: Wrap(
                          children: [
                            const Text('Acepto los '),
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Términos y Condiciones'),
                                    content: SingleChildScrollView(
                                      child: Text(
                                        'Términos y condiciones de uso de TechStore...\n\n'
                                        '1. Uso aceptable de la plataforma\n'
                                        '2. Protección de datos personales\n'
                                        '3. Derechos y responsabilidades\n'
                                        '4. Política de devoluciones\n'
                                        '5. Limitación de responsabilidad',
                                        style: TextStyle(color: Colors.grey[700]),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cerrar'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Text(
                                'términos y condiciones',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Botón de registro
                  ElevatedButton(
                    onPressed: _cargando ? null : _registrarse,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: _cargando
                        ? const SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add, size: 20),
                              SizedBox(width: 8),
                              Text('Crear Cuenta'),
                            ],
                          ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Enlace a login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿Ya tienes cuenta?'),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: _cargando ? null : () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Text(
                          'Inicia Sesión',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}