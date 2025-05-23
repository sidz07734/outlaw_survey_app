import 'dart:convert';
import 'package:http/http.dart' as http;

class SurveyService {
  final String baseUrl = 'http://localhost:5000/api';

  // Enhanced survey generation with better error handling
  Future<List<String>> generateSurvey(String productIdea) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/surveys/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'productIdea': productIdea.trim()}),
      ).timeout(
        const Duration(seconds: 60), // 60 second timeout for AI generation
        onTimeout: () {
          throw Exception('AI generation timed out. Please try again with a shorter product description.');
        },
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final survey = data['data'];
        final questions = List<String>.from(survey['questions']);
        
        if (questions.isEmpty) {
          throw Exception('No questions were generated. Please try a different product idea.');
        }
        
        return questions;
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Invalid product idea provided');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. AI service might be unavailable. Please try again.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to generate survey');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('connection')) {
        throw Exception('Cannot connect to AI service. Please check if the server is running.');
      } else if (e.toString().contains('timeout')) {
        throw Exception('AI generation took too long. Please try again.');
      } else {
        throw Exception('Error generating survey: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  // NEW: Regenerate single question
  Future<String> regenerateQuestion(String productIdea, int questionIndex) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/surveys/regenerate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'productIdea': productIdea.trim(),
          'questionIndex': questionIndex,
        }),
      ).timeout(
        const Duration(seconds: 30), // Shorter timeout for single question
        onTimeout: () {
          throw Exception('Question regeneration timed out. Please try again.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newQuestion = data['data']['newQuestion'] as String;
        
        if (newQuestion.isEmpty) {
          throw Exception('Failed to generate new question. Please try again.');
        }
        
        return newQuestion;
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Invalid regeneration request');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to regenerate question');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('connection')) {
        throw Exception('Cannot connect to AI service for regeneration.');
      } else if (e.toString().contains('timeout')) {
        throw Exception('Question regeneration timed out. Please try again.');
      } else {
        throw Exception('Error regenerating question: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  // NEW: Get all surveys with pagination
  Future<Map<String, dynamic>> getSurveys({int page = 1, int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/surveys?page=$page&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timed out while fetching surveys.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'surveys': data['data'] ?? [],
          'total': data['total'] ?? 0,
          'page': data['page'] ?? 1,
          'pages': data['pages'] ?? 1,
          'count': data['count'] ?? 0,
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch surveys');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('connection')) {
        throw Exception('Cannot connect to server to fetch surveys.');
      } else {
        throw Exception('Error fetching surveys: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  // NEW: Get specific survey by ID
  Future<Map<String, dynamic>> getSurveyById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/surveys/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timed out while fetching survey.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else if (response.statusCode == 404) {
        throw Exception('Survey not found');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch survey');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('connection')) {
        throw Exception('Cannot connect to server to fetch survey.');
      } else {
        throw Exception('Error fetching survey: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  // NEW: Test AI connection and health
  Future<Map<String, dynamic>> testAIConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/surveys/test-ollama'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception('AI health check timed out.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'healthy',
          'model': data['data']['model'] ?? 'unknown',
          'responseTime': data['data']['responseTime'] ?? 'unknown',
          'testQuestion': data['data']['testQuestion'] ?? 'No test question',
          'message': data['message'] ?? 'AI is working!'
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'status': 'error',
          'error': error['error'] ?? 'AI connection failed',
          'details': error['details'] ?? 'Unknown error'
        };
      }
    } catch (e) {
      return {
        'status': 'offline',
        'error': 'Cannot connect to AI service',
        'details': e.toString().replaceAll('Exception: ', '')
      };
    }
  }

  // NEW: Check server health
  Future<bool> isServerHealthy() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl.replaceAll('/api', '')}/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Health check timeout'),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // NEW: Get server status information
  Future<Map<String, dynamic>> getServerStatus() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl.replaceAll('/api', '')}/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Server status check timed out.');
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server returned error status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Cannot get server status: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }
}