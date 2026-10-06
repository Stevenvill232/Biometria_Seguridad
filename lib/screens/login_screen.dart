import 'package:flutter/material.dart';
import '../services/biometric_service.dart';
import '../services/fake_auth_api.dart';
import '../services/token_storage.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _bio = BiometricService();
  final _storage = TokenStorage();
  final _api = FakeAuthApi();

  final _emailCtrl = TextEditingController(text: 'demo@demo.com');
  final _passCtrl = TextEditingController(text: '1234');

  bool _hasSavedToken = false; // ¿ya hay sesión guardada?
  bool _bioAvailable = false;  // ¿el dispositivo tiene biometría?
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final token = await _storage.readToken();
    final available = await _bio.isAvailable();
    if (!mounted) return;
    setState(() {
      _hasSavedToken = token != null;
      _bioAvailable = available;
    });
  }

  /// Login normal con usuario y contraseña -> guarda el token cifrado.
  Future<void> _loginWithPassword() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await _api.login(_emailCtrl.text, _passCtrl.text);
      await _storage.saveToken(token);
      _goHome(token);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Login con huella/FaceID -> si pasa, leemos el token del almacenamiento seguro.
  Future<void> _loginWithBiometrics() async {
    setState(() => _error = null);
    final result = await _bio.authenticate(reason: 'Usa tu huella para entrar');
    switch (result) {
      case BiometricResult.success:
        final token = await _storage.readToken();
        if (token != null) {
          _goHome(token);
        } else {
          setState(() => _error = 'No hay sesión guardada. Inicia con contraseña.');
        }
        break;
      case BiometricResult.failed:
        setState(() => _error = 'Autenticación fallida o cancelada');
        break;
      case BiometricResult.notAvailable:
        setState(() => _error = 'Biometría no disponible en este dispositivo');
        break;
      case BiometricResult.error:
        setState(() => _error = 'Error de biometría (¿demasiados intentos?)');
        break;
    }
  }

  void _goHome(String token) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen(token: token)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.lock_outline, size: 72),
            const SizedBox(height: 24),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Correo', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _loginWithPassword,
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Entrar con contraseña'),
            ),
            // El botón biométrico solo aparece si hay token guardado Y biometría disponible
            if (_hasSavedToken && _bioAvailable) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loginWithBiometrics,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Entrar con huella / Face ID'),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            Text(
              _bioAvailable
                  ? 'Biometría disponible ✅'
                  : 'Biometría NO disponible (registra una huella en el emulador)',
              textAlign: TextAlign.center,
            ),
            const Text('Credenciales demo: demo@demo.com / 1234', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}