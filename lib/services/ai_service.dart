import 'dart:convert';
import 'package:http/http.dart' as http;

/// Cliente mínimo de la API de Gemini (REST).
/// La API key NO está en el código: llega desde flutter_secure_storage.
class AiService {
  // Se cambia a un nombre de modelo válido en la API.
  static const String model = 'gemini-3.8-flash';

  // Historial para que el modelo recuerde la conversación.
  final List<Map<String, dynamic>> _history = [];

  Future<String> ask(String apiKey, String prompt) async {
    _history.add({
      'role': 'user',
      'parts': [
        {'text': prompt}
      ]
    });

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
    );

    final res = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: jsonEncode({
            'system_instruction': {
              'parts': [
                {
                  'text':
                      'Eres un asistente de seguridad móvil. Responde en español, claro y en máximo 5 líneas.'
                }
              ]
            },
            'contents': _history,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) {
      _history.removeLast(); // No guardamos el mensaje si falló
      throw Exception(
          'Error ${res.statusCode}: revisa tu API key o el modelo (${res.body})');
    }

    final data = jsonDecode(res.body);
    final text =
        data['candidates'][0]['content']['parts'][0]['text'] as String;

    _history.add({
      'role': 'model',
      'parts': [
        {'text': text}
      ]
    });

    return text;
  }
}