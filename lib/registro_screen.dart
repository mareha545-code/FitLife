import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const Color verdeRegistro = Color(0xFF123D32);
const Color verdeAccento = Color(0xFF21865A);
const Color fondoRegistro = Color(0xFFF3F7F4);

class RegistroScreen extends StatefulWidget {
  final VoidCallback onRegistroCompleto;

  const RegistroScreen({
    super.key,
    required this.onRegistroCompleto,
  });

  @override
  State<RegistroScreen> createState() =>
      _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final nombreController = TextEditingController();
  final correoController = TextEditingController();
  final passwordController = TextEditingController();

  final secureStorage = const FlutterSecureStorage();

  bool mostrarPassword = false;
  bool guardando = false;

  bool get tieneMayuscula =>
      RegExp(r'[A-Z]').hasMatch(passwordController.text);

  bool get tieneMinuscula =>
      RegExp(r'[a-z]').hasMatch(passwordController.text);

  bool get tieneNumero =>
      RegExp(r'[0-9]').hasMatch(passwordController.text);

  bool get tieneEspecial =>
      RegExp(r'[^A-Za-z0-9\s]')
          .hasMatch(passwordController.text);

  bool get passwordValida =>
      tieneMayuscula &&
          tieneMinuscula &&
          tieneNumero &&
          tieneEspecial;

  void mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> registrarUsuario() async {
    if (guardando) return;

    final nombre = nombreController.text.trim();
    final correo = correoController.text.trim();
    final password = passwordController.text;

    List<String> errores = [];

    if (nombre.isEmpty) {
      errores.add('Ingresa tu nombre.');
    }

    if (!RegExp(
      r'^[A-Za-z0-9._%+-]+@gmail\.com$',
      caseSensitive: false,
    ).hasMatch(correo)) {
      errores.add(
        'El correo debe ser válido y terminar en @gmail.com.',
      );
    }

    if (!tieneMayuscula) {
      errores.add('Agrega al menos una letra mayúscula.');
    }

    if (!tieneMinuscula) {
      errores.add('Agrega al menos una letra minúscula.');
    }

    if (!tieneNumero) {
      errores.add('Agrega al menos un número.');
    }

    if (!tieneEspecial) {
      errores.add('Agrega al menos un carácter especial.');
    }

    if (errores.isNotEmpty) {
      mostrarMensaje(errores.join('\n'));
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Guardar los datos del usuario.

      await prefs.setString('nombreUsuario', nombre);
      await prefs.setString('correoUsuario', correo);

      // Guardar la contraseña en almacenamiento seguro.

      await secureStorage.write(
        key: 'passwordUsuario',
        value: password,
      );

      await prefs.setBool('usuarioRegistrado', true);

      if (!mounted) return;

      mostrarMensaje(
        '¡Registro completado correctamente!',
      );

      widget.onRegistroCompleto();

    } catch (e) {
      if (!mounted) return;

      mostrarMensaje(
        'No se pudo guardar el registro: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          guardando = false;
        });
      }
    }
  }

  Widget campoTexto({
    required String titulo,
    required String hint,
    required IconData icono,
    required TextEditingController controller,
    bool password = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: verdeRegistro,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,
          obscureText: password && !mostrarPassword,
          onChanged: password
              ? (_) => setState(() {})
              : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icono,
              color: verdeAccento,
            ),
            suffixIcon: password
                ? IconButton(
              onPressed: () {
                setState(() {
                  mostrarPassword = !mostrarPassword;
                });
              },
              icon: Icon(
                mostrarPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
            )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 17,
              horizontal: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: Color(0xFFE0E8E2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: verdeAccento,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget requisito(String texto, bool cumplido) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(
            cumplido
                ? Icons.check_circle
                : Icons.circle_outlined,
            size: 18,
            color: cumplido
                ? verdeAccento
                : Colors.grey,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 12,
                color: cumplido
                    ? verdeRegistro
                    : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondoRegistro,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // ENCABEZADO

                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 25,
                  ),
                  decoration: BoxDecoration(
                    color: verdeRegistro,
                    borderRadius: BorderRadius.circular(24),
                  ),

                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'FITLIFE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 29,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Tu actividad, tu progreso',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 27),

                const Text(
                  'Crea tu cuenta',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: verdeRegistro,
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  'Regístrate para comenzar a monitorear '
                      'tu actividad física.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 25),

                // FORMULARIO

                campoTexto(
                  titulo: 'Nombre completo',
                  hint: 'Escribe tu nombre',
                  icono: Icons.person_outline,
                  controller: nombreController,
                ),

                const SizedBox(height: 18),

                campoTexto(
                  titulo: 'Correo electrónico',
                  hint: 'ejemplo@gmail.com',
                  icono: Icons.email_outlined,
                  controller: correoController,
                ),

                const SizedBox(height: 18),

                campoTexto(
                  titulo: 'Contraseña',
                  hint: 'Crea una contraseña segura',
                  icono: Icons.lock_outline,
                  controller: passwordController,
                  password: true,
                ),

                const SizedBox(height: 17),

                // VALIDACIONES DE CONTRASEÑA

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE0E8E2),
                    ),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text(
                        'Tu contraseña debe contener:',
                        style: TextStyle(
                          color: verdeRegistro,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 13),

                      requisito(
                        'Al menos una letra mayúscula (A-Z)',
                        tieneMayuscula,
                      ),

                      requisito(
                        'Al menos una letra minúscula (a-z)',
                        tieneMinuscula,
                      ),

                      requisito(
                        'Al menos un número (0-9)',
                        tieneNumero,
                      ),

                      requisito(
                        'Al menos un carácter especial (!@#...)',
                        tieneEspecial,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // BOTÓN REGISTRAR

                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: guardando
                        ? null
                        : registrarUsuario,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: verdeRegistro,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),

                    child: guardando
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add_alt_1),
                        SizedBox(width: 10),
                        Text(
                          'CREAR CUENTA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 17,
                      color: verdeAccento,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Tus datos se almacenan localmente',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
