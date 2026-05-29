import 'dart:convert';
import 'package:http/http.dart' as http;

class HustleAIService {
  static Future<String> generatePlan(String idea) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8787/generate-plan'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'idea': idea,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['result'] ?? 'No plan generated.';
    } else {
      throw Exception('Failed to generate plan');
    }
  }
}
