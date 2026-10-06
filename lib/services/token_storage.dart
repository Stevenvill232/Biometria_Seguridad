import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda datos sensibles de forma CIFRADA.
/// - Android: cifrado con llaves del Android Keystore.
/// - iOS: Keychain.
/// NUNCA uses SharedPreferences para tokens: queda en texto plano.
class TokenStorage {
  static const _kToken = 'auth_token';
  static const _kApiKey = 'ia_api_key';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  // ---- Token de sesión ----
  Future<void> saveToken(String token) => _storage.write(key: _kToken, value: token);
  Future<String?> readToken() => _storage.read(key: _kToken);
  Future<void> deleteToken() => _storage.delete(key: _kToken);

  // ---- API key de un servicio de IA (caso de uso real) ----
  Future<void> saveApiKey(String key) => _storage.write(key: _kApiKey, value: key);
  Future<String?> readApiKey() => _storage.read(key: _kApiKey);

  /// Borra TODO (útil al cerrar sesión).
  Future<void> clearAll() => _storage.deleteAll();
}