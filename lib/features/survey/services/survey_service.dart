import 'dart:convert';
import 'package:http/http.dart' as http;

class SurveyService {
  final String baseUrl = 'http://localhost:5000/api';

  Future<List<String>> generateSurvey(String productIdea) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/surveys/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'productIdea': productIdea}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final survey = data['data'];
        return List<String>.from(survey['questions']);
      } else {
        throw Exception('Failed to generate survey: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }
}