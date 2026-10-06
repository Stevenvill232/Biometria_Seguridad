/// Simula un backend. En un proyecto real aquí iría una llamada HTTP
/// (por ejemplo con Dio/http) que devuelve un JWT.
class FakeAuthApi {
  static const _demoEmail = 'demo@demo.com';
  static const _demoPass = '1234';

  Future<String> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800)); // "red"
    if (email.trim() == _demoEmail && password == _demoPass) {
      // Token falso con forma de JWT
      return 'eyJhbGciOiJIUzI1NiJ9.demo_payload.${DateTime.now().millisecondsSinceEpoch}';
    }
    throw Exception('Credenciales incorrectas');
  }
}