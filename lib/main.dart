import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pedometer/pedometer.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'database_helper.dart';
import 'history_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FitLifeApp());
}

// Paleta FitLife: blanco, azul turquesa y azul profundo.
const Color verde = Color(0xFF168EAF); // Color principal
const Color verdeClaro = Color(0xFF25B8D5); // Acento turquesa
const Color fondo = Color(0xFFF3F7FA);
const Color textoPrincipal = Color(0xFF263746);
const Color bordeSuave = Color(0xFFE5EDF1);

// ==========================================
// APLICACIÓN PRINCIPAL
// ==========================================

class FitLifeApp extends StatelessWidget {
  const FitLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitLife',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: fondo,
        colorScheme: ColorScheme.fromSeed(
          seedColor: verde,
          primary: verde,
          secondary: verdeClaro,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: textoPrincipal,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textoPrincipal,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          labelStyle: const TextStyle(color: Color(0xFF71818C)),
          hintStyle: const TextStyle(color: Color(0xFFA0ADB5)),
          prefixIconColor: verde,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: bordeSuave),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: bordeSuave),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: verdeClaro, width: 1.6),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: verde,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: .3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: bordeSuave),
          ),
        ),
      ),
      home: const AccessGate(),
    );
  }
}


// ==========================================
// CUENTAS: REGISTRO, INICIO DE SESIÓN Y ACCESO
// ==========================================

class AccountStore {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _key = 'fitlife_accounts';

  static Future<Map<String, dynamic>> readAccounts() async {
    final raw = await _storage.read(key: _key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        // Si el contenido anterior no se puede leer, se intenta recuperar
        // la cuenta individual que utilizaba la versión anterior de FitLife.
      }
    }

    // Migración automática de la cuenta creada con la versión anterior.
    final prefs = await SharedPreferences.getInstance();
    final oldEmail = prefs.getString('correoUsuario')?.trim().toLowerCase();
    final oldName = prefs.getString('nombreUsuario');
    final oldPassword = await _storage.read(key: 'passwordUsuario');
    if (oldEmail != null && oldEmail.isNotEmpty && oldName != null && oldPassword != null) {
      final recovered = <String, dynamic>{
        oldEmail: {'nombre': oldName, 'password': oldPassword},
      };
      await saveAccounts(recovered);
      return recovered;
    }
    return {};
  }

  static Future<void> saveAccounts(Map<String, dynamic> accounts) async {
    await _storage.write(key: _key, value: jsonEncode(accounts));
  }
}

class AccessGate extends StatelessWidget {
  const AccessGate({super.key});

  @override
  Widget build(BuildContext context) => const StartScreen();
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  void abrir(BuildContext context, Widget pantalla) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 35),
                  decoration: BoxDecoration(color: verde, borderRadius: BorderRadius.circular(24)),
                  child: const Column(children: [
                    Icon(Icons.fitness_center, color: Colors.white, size: 55),
                    SizedBox(height: 12),
                    Text('FITLIFE', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4)),
                    SizedBox(height: 7),
                    Text('Tu actividad, tu progreso', style: TextStyle(color: Colors.white70)),
                  ]),
                ),
                const SizedBox(height: 35),
                const Text('Bienvenido', textAlign: TextAlign.center, style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold, color: verde)),
                const SizedBox(height: 8),
                const Text('Inicia sesión o crea una cuenta para continuar.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 28),
                SizedBox(height: 54, child: ElevatedButton.icon(
                  onPressed: () => abrir(context, const LoginScreen()),
                  icon: const Icon(Icons.login), label: const Text('YA TENGO UNA CUENTA'),
                  style: ElevatedButton.styleFrom(backgroundColor: verde, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                )),
                const SizedBox(height: 13),
                SizedBox(height: 54, child: OutlinedButton.icon(
                  onPressed: () => abrir(context, const RegistroScreen()),
                  icon: const Icon(Icons.person_add_alt_1), label: const Text('CREAR UNA CUENTA NUEVA'),
                  style: OutlinedButton.styleFrom(foregroundColor: verde, side: const BorderSide(color: verde), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final nombreController = TextEditingController();
  final correoController = TextEditingController();
  final passwordController = TextEditingController();
  bool mostrarPassword = false;
  bool guardando = false;

  String get password => passwordController.text;
  bool get tieneMayuscula => RegExp(r'[A-Z]').hasMatch(password);
  bool get tieneMinuscula => RegExp(r'[a-z]').hasMatch(password);
  bool get tieneNumero => RegExp(r'[0-9]').hasMatch(password);
  bool get tieneEspecial => RegExp(r'[^A-Za-z0-9\s]').hasMatch(password);

  void mostrarMensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating));
  }

  Future<void> registrarUsuario() async {
    if (guardando) return;
    final nombre = nombreController.text.trim();
    final correo = correoController.text.trim().toLowerCase();
    final clave = passwordController.text;
    final errores = <String>[];

    if (nombre.isEmpty) errores.add('Ingresa tu nombre.');
    if (!RegExp(r'^[A-Za-z0-9._%+-]+@gmail\.com$').hasMatch(correo)) {
      errores.add('El correo debe ser válido y terminar en @gmail.com.');
    }
    if (!tieneMayuscula) errores.add('Agrega al menos una mayúscula (A-Z).');
    if (!tieneMinuscula) errores.add('Agrega al menos una minúscula (a-z).');
    if (!tieneNumero) errores.add('Agrega al menos un número (0-9).');
    if (!tieneEspecial) errores.add('Agrega al menos un carácter especial (! @ #...).');
    if (errores.isNotEmpty) {
      mostrarMensaje(errores.join('\n'));
      return;
    }

    setState(() => guardando = true);
    try {
      final cuentas = await AccountStore.readAccounts();
      if (cuentas.containsKey(correo)) {
        mostrarMensaje('Ese correo ya tiene una cuenta. Inicia sesión o utiliza otro correo.');
        return;
      }
      cuentas[correo] = {'nombre': nombre, 'password': clave};
      await AccountStore.saveAccounts(cuentas);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => BiometricScreen(userName: nombre, email: correo),
      ));
    } catch (e) {
      mostrarMensaje('No se pudo guardar el registro. Inténtalo nuevamente.');
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  Widget campo({required String titulo, required String sugerencia, required IconData icono,
    required TextEditingController controller, bool esPassword = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600, color: verde)),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        obscureText: esPassword && !mostrarPassword,
        keyboardType: titulo == 'Correo electrónico' ? TextInputType.emailAddress : TextInputType.text,
        autocorrect: false,
        onChanged: esPassword ? (_) => setState(() {}) : null,
        decoration: InputDecoration(
          hintText: sugerencia, prefixIcon: Icon(icono, color: verdeClaro),
          suffixIcon: esPassword ? IconButton(
            onPressed: () => setState(() => mostrarPassword = !mostrarPassword),
            icon: Icon(mostrarPassword ? Icons.visibility_off : Icons.visibility),
          ) : null,
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0E8E2))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: verdeClaro, width: 1.5)),
        ),
      ),
    ]);
  }

  Widget requisito(String texto, bool correcto) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Icon(correcto ? Icons.check_circle : Icons.radio_button_unchecked, color: correcto ? verdeClaro : Colors.grey, size: 18),
      const SizedBox(width: 9), Expanded(child: Text(texto, style: const TextStyle(fontSize: 12, color: Colors.black87))),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta'), backgroundColor: verde, foregroundColor: Colors.white),
      body: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Regístrate en FitLife', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: verde)),
          const SizedBox(height: 6),
          const Text('Completa tus datos para proteger tu perfil y comenzar a entrenar.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 22),
          campo(titulo: 'Nombre', sugerencia: 'Escribe tu nombre', icono: Icons.person_outline, controller: nombreController),
          const SizedBox(height: 17),
          campo(titulo: 'Correo electrónico', sugerencia: 'ejemplo@gmail.com', icono: Icons.email_outlined, controller: correoController),
          const SizedBox(height: 17),
          campo(titulo: 'Contraseña', sugerencia: 'Crea una contraseña segura', icono: Icons.lock_outline, controller: passwordController, esPassword: true),
          const SizedBox(height: 15),
          Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE0E8E2))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('La contraseña debe contener:', style: TextStyle(fontWeight: FontWeight.bold, color: verde)),
              const SizedBox(height: 12),
              requisito('Una letra mayúscula (A-Z)', tieneMayuscula),
              requisito('Una letra minúscula (a-z)', tieneMinuscula),
              requisito('Un número (0-9)', tieneNumero),
              requisito('Un carácter especial (!@#...)', tieneEspecial),
            ]),
          ),
          const SizedBox(height: 23),
          SizedBox(height: 54, child: ElevatedButton.icon(
            onPressed: guardando ? null : registrarUsuario,
            icon: guardando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.person_add_alt_1),
            label: Text(guardando ? 'GUARDANDO...' : 'CREAR CUENTA', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            style: ElevatedButton.styleFrom(backgroundColor: verde, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          )),
          const SizedBox(height: 15),
          TextButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())), child: const Text('¿Ya tienes cuenta? Inicia sesión')),
        ]),
      ))),
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final correoController = TextEditingController();
  final passwordController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();

  bool cargando = false;
  bool mostrarPassword = false;

  // INGRESAR CON CONTRASEÑA
  Future<void> iniciarSesion() async {
    if (cargando) return;

    final correo = correoController.text.trim().toLowerCase();
    final clave = passwordController.text;

    if (correo.isEmpty || clave.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu correo y contraseña.')),
      );
      return;
    }

    setState(() => cargando = true);

    try {
      final cuentas = await AccountStore.readAccounts();
      final cuenta = cuentas[correo];

      if (cuenta == null || cuenta['password'] != clave) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Correo o contraseña incorrectos.')),
          );
        }
        return;
      }

      if (!mounted) return;

      // La contraseña permite entrar directamente a la pantalla principal.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FitnessHome(
            userName: cuenta['nombre'] as String,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudieron consultar las cuentas.')),
        );
      }
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  // INGRESAR CON HUELLA
  Future<void> iniciarConHuella() async {
    if (cargando) return;

    final correo = correoController.text.trim().toLowerCase();

    if (correo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero escribe el correo de tu cuenta.')),
      );
      return;
    }

    setState(() => cargando = true);

    try {
      final cuentas = await AccountStore.readAccounts();
      final cuenta = cuentas[correo];

      if (cuenta == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No existe una cuenta con ese correo.')),
          );
        }
        return;
      }

      // Verifica la huella directamente, sin abrir otra pantalla.
      final disponible = await auth.canCheckBiometrics;
      final compatible = await auth.isDeviceSupported();

      if (!disponible || !compatible) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configura una huella digital en los ajustes del celular.'),
            ),
          );
        }
        return;
      }

      final resultado = await auth.authenticate(
        localizedReason: 'Coloca tu huella para ingresar a FitLife',
        biometricOnly: true,
      );

      if (!mounted) return;

      if (resultado) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FitnessHome(
              userName: cuenta['nombre'] as String,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se completó la autenticación.')),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error biométrico: ${e.message}')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo verificar la cuenta.')),
        );
      }
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Iniciar sesión'),
      backgroundColor: verde,
      foregroundColor: Colors.white,
    ),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.fitness_center, color: verde, size: 55),
              const SizedBox(height: 12),
              const Text(
                'Qué gusto tenerte de vuelta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: verde,
                ),
              ),
              const SizedBox(height: 25),
              TextField(
                controller: correoController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: !mostrarPassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                          () => mostrarPassword = !mostrarPassword,
                    ),
                    icon: Icon(
                      mostrarPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // OPCIÓN 1: CONTRASEÑA
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: cargando ? null : iniciarSesion,
                  icon: const Icon(Icons.lock_open),
                  label: Text(
                    cargando ? 'VALIDANDO...' : 'INGRESAR CON CONTRASEÑA',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: verde,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('O TAMBIÉN'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 14),

              // OPCIÓN 2: HUELLA DIGITAL
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: cargando ? null : iniciarConHuella,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('INGRESAR CON HUELLA'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: verde,
                    side: const BorderSide(color: verde, width: 1.5),
                  ),
                ),
              ),
              if (cargando) ...[
                const SizedBox(height: 18),
                const Center(child: CircularProgressIndicator()),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const RegistroScreen()),
                ),
                child: const Text('¿No tienes cuenta? Regístrate'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  void dispose() {
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

// ==========================================
// AUTENTICACIÓN BIOMÉTRICA
// ==========================================

class BiometricScreen extends StatefulWidget {
  final String userName;
  final String email;
  const BiometricScreen({super.key, required this.userName, required this.email});

  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  String mensaje = 'Identifícate para continuar';
  bool cargando = false;

  Future<void> verificarHuella() async {
    setState(() { cargando = true; mensaje = 'Verificando huella...'; });
    try {
      final disponible = await auth.canCheckBiometrics;
      final compatible = await auth.isDeviceSupported();
      if (!disponible || !compatible) {
        if (!mounted) return;
        setState(() => mensaje = 'Configura una huella digital en los ajustes del celular.');
        return;
      }
      final resultado = await auth.authenticate(
        localizedReason: 'Coloca tu huella para ingresar a FitLife',
        biometricOnly: true,
      );
      if (!mounted) return;
      if (resultado) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => FitnessHome(userName: widget.userName),
        ));
      } else {
        setState(() => mensaje = 'No se completó la autenticación.');
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => mensaje = 'Error biométrico: ${e.message}');
    } catch (_) {
      if (!mounted) return;
      setState(() => mensaje = 'No fue posible verificar la huella.');
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: verde,
    appBar: AppBar(backgroundColor: verde, foregroundColor: Colors.white, elevation: 0),
    body: Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.fitness_center, size: 75, color: Colors.white),
        const SizedBox(height: 15),
        const Text('FITLIFE', style: TextStyle(fontSize: 35, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 3)),
        const Text('Tu actividad, tu progreso', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 35),
        Text('Hola, ${widget.userName}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 25),
        const Icon(Icons.fingerprint, size: 110, color: Colors.white),
        const SizedBox(height: 20),
        Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 25),
        ElevatedButton.icon(onPressed: cargando ? null : verificarHuella, icon: const Icon(Icons.fingerprint), label: Text(cargando ? 'Verificando...' : 'Ingresar con huella'), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: verde, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 17))),
        const SizedBox(height: 12),
        TextButton(onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AccessGate()), (_) => false), child: const Text('Volver al inicio', style: TextStyle(color: Colors.white70))),
      ],
    ))),
  );
}

// ==========================================
// PANTALLA PRINCIPAL DE FITLIFE
// ==========================================

class FitnessHome extends StatefulWidget {
  final String userName;
  const FitnessHome({super.key, required this.userName});

  @override
  State<FitnessHome> createState() =>
      _FitnessHomeState();
}

class _FitnessHomeState extends State<FitnessHome>
    with WidgetsBindingObserver {

  // SUSCRIPCIONES DE LOS SENSORES

  StreamSubscription<StepCount>? pasosSub;

  StreamSubscription<AccelerometerEvent>?
  acelerometroSub;

  StreamSubscription<GyroscopeEvent>?
  giroscopioSub;

  StreamSubscription<Position>? gpsSub;

  Timer? reloj;

  // ESTADOS

  bool entrenando = false;
  bool procesando = false;

  // PODÓMETRO

  int pasos = 0;
  int? pasosIniciales;

  // DISTANCIA

  double distancia = 0;

  // ACELERÓMETRO

  double ax = 0;
  double ay = 0;
  double az = 0;

  double aceleracion = 0;

  String intensidad = 'En reposo';

  // GIROSCOPIO

  double gx = 0;
  double gy = 0;
  double gz = 0;

  // TIEMPO

  DateTime? inicio;

  // RUTA GPS

  List<LatLng> recorrido = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  // ========================================
  // SOLICITAR PERMISOS
  // ========================================

  Future<bool> solicitarPermisos() async {
    final actividad =
    await Permission.activityRecognition.request();

    if (!actividad.isGranted) {
      mostrarMensaje(
        'Necesitamos permiso para contar tus pasos.',
      );
      return false;
    }

    final servicioGPS =
    await Geolocator.isLocationServiceEnabled();

    if (!servicioGPS) {
      mostrarMensaje(
        'Activa el GPS del dispositivo.',
      );
      return false;
    }

    LocationPermission permiso =
    await Geolocator.checkPermission();

    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      mostrarMensaje(
        'No tenemos permiso para acceder a tu ubicación.',
      );
      return false;
    }

    return true;
  }

  // ========================================
  // MENSAJES
  // ========================================

  void mostrarMensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
      ),
    );
  }

  // ========================================
  // INICIAR ENTRENAMIENTO
  // ========================================

  Future<void> iniciarEntrenamiento() async {
    if (procesando || entrenando) return;

    procesando = true;

    try {
      mostrarMensaje(
        'Solicitando permisos para iniciar...',
      );

      final autorizado = await solicitarPermisos();

      if (!autorizado || !mounted) return;

      final posicion =
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        entrenando = true;

        inicio = DateTime.now();

        pasos = 0;
        pasosIniciales = null;

        distancia = 0;

        aceleracion = 0;
        intensidad = 'En reposo';

        ax = 0;
        ay = 0;
        az = 0;

        gx = 0;
        gy = 0;
        gz = 0;

        recorrido = [
          LatLng(
            posicion.latitude,
            posicion.longitude,
          ),
        ];
      });

      iniciarSensores();
      iniciarReloj();

    } catch (e) {
      mostrarMensaje(
        'No se pudo iniciar el entrenamiento: $e',
      );
    } finally {
      procesando = false;
    }
  }

  // ========================================
  // RELOJ
  // ========================================

  void iniciarReloj() {
    reloj?.cancel();

    reloj = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        if (mounted && entrenando) {
          setState(() {});
        }
      },
    );
  }

  String get tiempo {
    if (inicio == null) return '00:00';

    final segundos =
        DateTime.now().difference(inicio!).inSeconds;

    final minutos = segundos ~/ 60;
    final resto = segundos % 60;

    return '${minutos.toString().padLeft(2, '0')}:'
        '${resto.toString().padLeft(2, '0')}';
  }

  // ========================================
  // ACTIVAR SENSORES
  // ========================================

  void iniciarSensores() {
    if (!entrenando) return;

    // PODÓMETRO

    if (pasosSub == null) {
      try {
        pasosSub = Pedometer.stepCountStream.listen(
              (event) {
            if (!mounted || !entrenando) return;

            setState(() {
              pasosIniciales ??= event.steps;

              pasos = max(
                0,
                event.steps - pasosIniciales!,
              );
            });
          },
          onError: (error) {
            mostrarMensaje(
              'Podómetro no disponible.',
            );
          },
        );
      } catch (e) {
        mostrarMensaje(
          'Error al activar podómetro.',
        );
      }
    }

    // ACELERÓMETRO

    if (acelerometroSub == null) {
      try {
        acelerometroSub =
            accelerometerEventStream().listen(
                  (event) {
                if (!mounted || !entrenando) return;

                final magnitud = sqrt(
                  event.x * event.x +
                      event.y * event.y +
                      event.z * event.z,
                );

                final movimiento =
                (magnitud - 9.8).abs();

                setState(() {
                  ax = event.x;
                  ay = event.y;
                  az = event.z;

                  aceleracion = movimiento;

                  if (movimiento < 1.2) {
                    intensidad = 'En reposo';
                  } else if (movimiento < 3.0) {
                    intensidad = 'Caminata';
                  } else {
                    intensidad = 'Movimiento intenso';
                  }
                });
              },
              onError: (error) {
                mostrarMensaje(
                  'Acelerómetro no disponible.',
                );
              },
            );
      } catch (e) {
        mostrarMensaje(
          'Error al activar acelerómetro.',
        );
      }
    }

    // GIROSCOPIO

    if (giroscopioSub == null) {
      try {
        giroscopioSub =
            gyroscopeEventStream().listen(
                  (event) {
                if (!mounted || !entrenando) return;

                setState(() {
                  gx = event.x;
                  gy = event.y;
                  gz = event.z;
                });
              },
              onError: (error) {
                mostrarMensaje(
                  'Giroscopio no disponible.',
                );
              },
            );
      } catch (e) {
        mostrarMensaje(
          'Error al activar giroscopio.',
        );
      }
    }

    // GPS EN TIEMPO REAL

    if (gpsSub == null) {
      try {
        gpsSub = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen(
              (position) {
            if (!mounted || !entrenando) return;

            final nueva = LatLng(
              position.latitude,
              position.longitude,
            );

            setState(() {
              if (recorrido.isNotEmpty) {
                final anterior = recorrido.last;

                final metros =
                Geolocator.distanceBetween(
                  anterior.latitude,
                  anterior.longitude,
                  nueva.latitude,
                  nueva.longitude,
                );

                if (metros >= 2) {
                  distancia += metros;
                  recorrido.add(nueva);
                }
              } else {
                recorrido.add(nueva);
              }
            });
          },
          onError: (error) {
            mostrarMensaje(
              'Error al obtener GPS.',
            );
          },
        );
      } catch (e) {
        mostrarMensaje(
          'No se pudo activar GPS.',
        );
      }
    }
  }

  // ========================================
  // DETENER Y LIBERAR SENSORES
  // ========================================

  Future<void> detenerSensores() async {
    await pasosSub?.cancel();
    await acelerometroSub?.cancel();
    await giroscopioSub?.cancel();
    await gpsSub?.cancel();

    pasosSub = null;
    acelerometroSub = null;
    giroscopioSub = null;
    gpsSub = null;
  }

  void detenerReloj() {
    reloj?.cancel();
    reloj = null;
  }

  // ========================================
  // CONTROL DEL CICLO DE VIDA
  // ========================================

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {

      detenerSensores();
      detenerReloj();
    }

    if (state == AppLifecycleState.resumed &&
        entrenando) {

      iniciarSensores();
      iniciarReloj();
    }
  }

  // ========================================
  // FINALIZAR Y GUARDAR ENTRENAMIENTO
  // ========================================

  Future<void> finalizarEntrenamiento() async {
    if (!entrenando ||
        procesando ||
        inicio == null) {
      return;
    }

    procesando = true;

    try {
      final duracion =
          DateTime.now().difference(inicio!).inSeconds;

      await detenerSensores();
      detenerReloj();

      final rutaJSON = jsonEncode(
        recorrido.map((p) {
          return {
            'lat': p.latitude,
            'lng': p.longitude,
          };
        }).toList(),
      );

      await DatabaseHelper.guardarEntrenamiento(
        fecha: inicio!.toIso8601String(),
        duracion: duracion,
        pasos: pasos,
        distancia: distancia,
        ruta: rutaJSON,
      );

      if (!mounted) return;

      setState(() {
        entrenando = false;
        inicio = null;
      });

      mostrarMensaje(
        '¡Entrenamiento guardado correctamente!',
      );

    } catch (e) {
      if (!mounted) return;

      mostrarMensaje(
        'Error al guardar entrenamiento: $e',
      );
    } finally {
      procesando = false;
    }
  }

  // ========================================
  // REGRESAR AL INICIO / CERRAR SESIÓN
  // ========================================

  Future<bool> volverAlInicio({bool cerrarSesion = false}) async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(cerrarSesion ? 'Cerrar sesión' : 'Volver al inicio'),
        content: Text(entrenando
            ? 'Hay un entrenamiento en curso. Si continúas, se detendrán los sensores y este entrenamiento no se guardará. ¿Deseas continuar?'
            : (cerrarSesion ? '¿Deseas cerrar tu sesión?' : '¿Deseas regresar a la pantalla principal?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('CANCELAR')),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('CONTINUAR')),
        ],
      ),
    );
    if (salir != true || !mounted) return false;
    await detenerSensores();
    detenerReloj();
    if (!mounted) return true;
    setState(() { entrenando = false; inicio = null; });
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AccessGate()),
          (_) => false,
    );
    return true;
  }

  // ========================================
  // INTERFAZ PRINCIPAL
  // ========================================

  @override
  Widget build(BuildContext context) {
    final double progresoPasos = (pasos / 10000).clamp(0.0, 1.0).toDouble();

    return WillPopScope(
      onWillPop: () => volverAlInicio(),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: verdeClaro.withOpacity(.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fitness_center, color: verde, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('FITLIFE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    Text('Hola, ${widget.userName}', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF71818C), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Historial',
              icon: const Icon(Icons.bar_chart_rounded),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryPage()),
                );
              },
            ),
            IconButton(
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => volverAlInicio(cerrarSesion: true),
            ),
            const SizedBox(width: 5),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tu actividad de hoy', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textoPrincipal)),
              const SizedBox(height: 5),
              const Text('Cada paso cuenta. Sigue avanzando.', style: TextStyle(fontSize: 13, color: Color(0xFF71818C))),
              const SizedBox(height: 18),

              // Resumen visual del progreso de pasos.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: bordeSuave),
                  boxShadow: [BoxShadow(color: const Color(0xFF183B4A).withOpacity(.045), blurRadius: 18, offset: const Offset(0, 7))],
                ),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('PROGRESO DE PASOS', style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: Color(0xFF71818C))),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: 190,
                      height: 190,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: CircularProgressIndicator(
                              value: progresoPasos,
                              strokeWidth: 12,
                              strokeCap: StrokeCap.round,
                              backgroundColor: const Color(0xFFEAF1F4),
                              valueColor: const AlwaysStoppedAnimation<Color>(verdeClaro),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${(progresoPasos * 100).round()}%', style: const TextStyle(fontSize: 15, color: verde, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 5),
                              Text('$pasos', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: textoPrincipal, height: 1.1)),
                              const SizedBox(height: 4),
                              const Text('pasos', style: TextStyle(fontSize: 13, color: Color(0xFF71818C))),
                              const SizedBox(height: 7),
                              const Text('Objetivo: 10,000', style: TextStyle(fontSize: 11, color: Color(0xFF9AA8B0))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _datoResumen(Icons.route_rounded, '${(distancia / 1000).toStringAsFixed(2)} km', 'Distancia'),
                        Container(width: 1, height: 38, color: bordeSuave),
                        _datoResumen(Icons.timer_outlined, tiempo, 'Duración'),
                        Container(width: 1, height: 38, color: bordeSuave),
                        _datoResumen(Icons.directions_run_rounded, intensidad, 'Actividad'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: tarjeta(Icons.directions_walk_rounded, 'Pasos', '$pasos')),
                  const SizedBox(width: 12),
                  Expanded(child: tarjeta(Icons.route_rounded, 'Distancia GPS', '${(distancia / 1000).toStringAsFixed(2)} km')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: tarjeta(Icons.timer_outlined, 'Duración', tiempo)),
                  const SizedBox(width: 12),
                  Expanded(child: tarjeta(Icons.speed_rounded, 'Movimiento', intensidad)),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: procesando ? null : entrenando ? finalizarEntrenamiento : iniciarEntrenamiento,
                  icon: Icon(entrenando ? Icons.stop_circle_outlined : Icons.play_circle_outline_rounded, size: 23),
                  label: Text(
                    procesando ? 'PROCESANDO...' : entrenando ? 'FINALIZAR ENTRENAMIENTO' : 'INICIAR ENTRENAMIENTO',
                    style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: entrenando ? const Color(0xFFE45D67) : verde,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 26),

              tituloSeccion('Acelerómetro'),
              tarjetaSensor('Aceleración X', ax, 'm/s²'),
              tarjetaSensor('Aceleración Y', ay, 'm/s²'),
              tarjetaSensor('Aceleración Z', az, 'm/s²'),
              tarjetaSensor('Intensidad de movimiento', aceleracion, 'm/s²'),
              const SizedBox(height: 18),

              tituloSeccion('Giroscopio'),
              tarjetaSensor('Eje X', gx, 'rad/s'),
              tarjetaSensor('Eje Y', gy, 'rad/s'),
              tarjetaSensor('Eje Z', gz, 'rad/s'),
              const SizedBox(height: 20),

              tituloSeccion('Mi recorrido GPS'),
              Container(
                height: 280,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: bordeSuave),
                  boxShadow: [BoxShadow(color: const Color(0xFF183B4A).withOpacity(.04), blurRadius: 14, offset: const Offset(0, 5))],
                ),
                clipBehavior: Clip.antiAlias,
                child: recorrido.isEmpty
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(22),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_outlined, size: 42, color: Color(0xFF9AA8B0)),
                        SizedBox(height: 10),
                        Text('Inicia tu entrenamiento para visualizar tu recorrido.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF71818C))),
                      ],
                    ),
                  ),
                )
                    : FlutterMap(
                  options: MapOptions(initialCenter: recorrido.last, initialZoom: 16),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.fitlife',
                    ),
                    if (recorrido.length > 1)
                      PolylineLayer(
                        polylines: [Polyline(points: recorrido, strokeWidth: 5, color: verdeClaro)],
                      ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: recorrido.last,
                          width: 45,
                          height: 45,
                          child: const Icon(Icons.location_on, color: Color(0xFFE45D67), size: 38),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text('FITLIFE  •  Tu progreso comienza hoy', style: TextStyle(color: Color(0xFF71818C), fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: .4)),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _datoResumen(IconData icono, String valor, String etiqueta) {
    return Expanded(
      child: Column(
        children: [
          Icon(icono, color: verde, size: 20),
          const SizedBox(height: 6),
          Text(valor, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textoPrincipal)),
          const SizedBox(height: 3),
          Text(etiqueta, style: const TextStyle(fontSize: 10, color: Color(0xFF82919A))),
        ],
      ),
    );
  }

  // ========================================
  // TARJETAS DE INFORMACIÓN
  // ========================================

  Widget tarjeta(IconData icono, String titulo, String valor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: bordeSuave),
        boxShadow: [BoxShadow(color: const Color(0xFF183B4A).withOpacity(.035), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: verdeClaro.withOpacity(.13), borderRadius: BorderRadius.circular(13)),
            child: Icon(icono, size: 22, color: verde),
          ),
          const SizedBox(height: 10),
          Text(titulo, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF71818C), fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 5),
          Text(valor, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textoPrincipal)),
        ],
      ),
    );
  }

  Widget tituloSeccion(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 4, height: 21, decoration: BoxDecoration(color: verdeClaro, borderRadius: BorderRadius.circular(5))),
          const SizedBox(width: 9),
          Text(texto, style: const TextStyle(color: textoPrincipal, fontWeight: FontWeight.w800, fontSize: 18)),
        ],
      ),
    );
  }

  Widget tarjetaSensor(String nombre, double valor, String unidad) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bordeSuave),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: verdeClaro.withOpacity(.12), borderRadius: BorderRadius.circular(11)),
          child: const Icon(Icons.sensors_rounded, color: verde, size: 19),
        ),
        title: Text(nombre, style: const TextStyle(fontSize: 13, color: textoPrincipal, fontWeight: FontWeight.w600)),
        trailing: Text('${valor.toStringAsFixed(2)} $unidad',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: verde)),
      ),
    );
  }

  // ========================================
  // CERRAR Y LIBERAR RECURSOS
  // ========================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    detenerReloj();
    detenerSensores();

    super.dispose();
  }
}
