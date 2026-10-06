import 'package:flutter/material.dart';
import '../services/biometric_service.dart';
import '../services/token_storage.dart';
import 'ai_chat_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String token;
  const HomeScreen({super.key, required this.token});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = TokenStorage();
  final _bio = BiometricService();
  final _apiKeyCtrl = TextEditingController();

  bool _showToken = false;
  String? _savedApiKeyMasked;

  /// Pedimos biometría OTRA VEZ antes de mostrar un dato sensible.
  Future<void> _revealToken() async {
    final r = await _bio.authenticate(reason: 'Confirma para ver tu token');
    if (r == BiometricResult.success) setState(() => _showToken = true);
  }

  /// Caso de uso IA: guardar la API key de un LLM sin ponerla en el código.
  Future<void> _saveApiKey() async {
    if (_apiKeyCtrl.text.isEmpty) return;
    await _storage.saveApiKey(_apiKeyCtrl.text);
    final k = await _storage.readApiKey();
    if (k == null) return;
    setState(() => _savedApiKeyMasked = '••••${k.substring(k.length > 4 ? k.length - 4 : 0)}');
    _apiKeyCtrl.clear();
  }

  /// Abrir el asistente IA solo si pasa la huella.
  Future<void> _openAssistant() async {
    final r = await _bio.authenticate(reason: 'Confirma tu identidad para abrir el asistente');
    if (r == BiometricResult.success && mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiChatScreen()));
    }
  }

  Future<void> _logout() async {
    await _storage.clearAll(); // borra token y API key
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.token;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesión iniciada'),
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const Text('🔐 Token guardado de forma segura', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SelectableText(_showToken ? t : '${t.substring(0, 8)}••••••••••••'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _revealToken,
              icon: const Icon(Icons.visibility),
              label: const Text('Ver token completo (pide huella)'),
            ),
            const Divider(height: 40),
            const Text('🤖 Guardar API key de un modelo de IA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'API key (ej. sk-...)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _saveApiKey, child: const Text('Guardar cifrada')),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _openAssistant,
              icon: const Icon(Icons.smart_toy),
              label: const Text('Abrir asistente IA (pide huella)'),
            ),
            if (_savedApiKeyMasked != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Guardada: $_savedApiKeyMasked'),
              ),
          ],
        ),
      ),
    );
  }
}