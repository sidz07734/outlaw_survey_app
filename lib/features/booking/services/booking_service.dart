import 'dart:convert';
import 'package:http/http.dart' as http;

class BookingService {
  final String baseUrl = 'http://localhost:5000/api';

  Future<Map<String, dynamic>> createTimeSlot({
    required String creatorId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? email,  // Add email parameter
    List<String>? questions,  // Add questions parameter
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'creatorId': creatorId,
          'date': date.toIso8601String(),
          'startTime': startTime,
          'endTime': endTime,
          'email': email,  // Include email in request body
          'questions': questions,  // Include questions in request body
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to create time slot: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableSlots() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/available'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to fetch available slots: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  Future<Map<String, dynamic>> bookTimeSlot({
    required String id,
    required String smeId,
    String? email,  // Add email parameter
    List<String>? questions,  // Add questions parameter
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/bookings/book'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id,
          'smeId': smeId,
          'email': email,  // Include email in request body
          'questions': questions,  // Include questions in request body
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to book time slot: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  // Test email functionality directly
  Future<bool> testEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/simple-test-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to send test email: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error testing email: $e');
    }
  }
}