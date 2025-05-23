import 'dart:convert';
import 'package:http/http.dart' as http;

class BookingService {
  final String baseUrl = 'http://localhost:5000/api';

  // Enhanced time slot creation with better error handling and validation
  Future<Map<String, dynamic>> createTimeSlot({
    required String creatorId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? email,
    List<String>? questions,
  }) async {
    try {
      // Input validation
      if (creatorId.isEmpty) {
        throw Exception('Creator ID is required');
      }
      
      if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        throw Exception('Cannot create time slots for past dates');
      }
      
      if (email != null && !_isValidEmail(email)) {
        throw Exception('Invalid email format provided');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/bookings/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'creatorId': creatorId.trim(),
          'date': date.toIso8601String(),
          'startTime': startTime.trim(),
          'endTime': endTime.trim(),
          'email': email?.trim(),
          'questions': questions,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out. Please try again.');
        },
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'booking': data['data'],
          'emailSent': data['email']?['sent'] ?? false,
          'emailMessageId': data['email']?['messageId'],
        };
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Invalid booking data provided');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create time slot');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('connection')) {
        throw Exception('Cannot connect to booking service. Please check your internet connection.');
      } else if (e.toString().contains('timeout')) {
        throw Exception('Request timed out. Please try again.');
      } else {
        throw Exception('Booking creation failed: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  // Enhanced available slots fetching with filtering options
  Future<List<Map<String, dynamic>>> getAvailableSlots({
    DateTime? fromDate,
    DateTime? toDate,
    String? creatorId,
  }) async {
    try {
      String url = '$baseUrl/bookings/available';
      
      // Add query parameters if provided
      List<String> queryParams = [];
      if (fromDate != null) {
        queryParams.add('fromDate=${fromDate.toIso8601String()}');
      }
      if (toDate != null) {
        queryParams.add('toDate=${toDate.toIso8601String()}');
      }
      if (creatorId != null && creatorId.isNotEmpty) {
        queryParams.add('creatorId=$creatorId');
      }
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timed out while fetching available slots.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final slots = List<Map<String, dynamic>>.from(data['data'] ?? []);
        
        // Filter out past slots on client side as backup
        final now = DateTime.now();
        return slots.where((slot) {
          try {
            final slotDate = DateTime.parse(slot['date']);
            return slotDate.isAfter(now.subtract(const Duration(days: 1)));
          } catch (e) {
            return true; // Keep slot if date parsing fails
          }
        }).toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch available slots');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('connection')) {
        throw Exception('Cannot connect to server to fetch available slots.');
      } else if (e.toString().contains('timeout')) {
        throw Exception('Request timed out while fetching slots.');
      } else {
        throw Exception('Error fetching available slots: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  // Enhanced booking with comprehensive validation
  Future<Map<String, dynamic>> bookTimeSlot({
    required String id,
    required String smeId,
    String? email,
    List<String>? questions,
  }) async {
    try {
      // Enhanced validation
      if (id.isEmpty) {
        throw Exception('Booking ID is required');
      }
      
      if (smeId.isEmpty) {
        throw Exception('SME ID is required');
      }
      
      if (email != null && !_isValidEmail(email)) {
        throw Exception('Invalid email format provided');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/bookings/book'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id.trim(),
          'smeId': smeId.trim(),
          'email': email?.trim(),
          'questions': questions,
        }),
      ).timeout(
        const Duration(seconds: 45), // Longer timeout for booking confirmation
        onTimeout: () {
          throw Exception('Booking request timed out. Please check if your booking was successful.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'booking': data['data'],
          'emailResults': data['emails'] ?? {},
          'success': true,
        };
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        String errorMessage = error['error'] ?? 'Invalid booking request';
        
        if (errorMessage.contains('already booked')) {
          errorMessage = 'This time slot has already been booked by someone else.';
        } else if (errorMessage.contains('not found')) {
          errorMessage = 'The selected time slot is no longer available.';
        }
        
        throw Exception(errorMessage);
      } else if (response.statusCode == 404) {
        throw Exception('The selected time slot was not found. It may have been removed.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to book time slot');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('connection')) {
        throw Exception('Cannot connect to booking service. Please check your connection.');
      } else if (e.toString().contains('timeout')) {
        throw Exception('Booking request timed out. Please verify if your booking was successful.');
      } else {
        throw Exception('Booking failed: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  // NEW: Get booking history for a user
  Future<List<Map<String, dynamic>>> getBookingHistory({
    String? creatorId,
    String? smeId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      String endpoint = '';
      if (creatorId != null && creatorId.isNotEmpty) {
        endpoint = '/creator/${creatorId.trim()}';
      } else if (smeId != null && smeId.isNotEmpty) {
        endpoint = '/sme/${smeId.trim()}';
      } else {
        endpoint = '';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/bookings$endpoint?page=$page&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timed out while fetching booking history.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch booking history');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('connection')) {
        throw Exception('Cannot connect to server to fetch booking history.');
      } else {
        throw Exception('Error fetching booking history: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  // NEW: Cancel a booking
  Future<bool> cancelBooking({
    required String bookingId,
    bool notifyParticipants = true,
  }) async {
    try {
      if (bookingId.isEmpty) {
        throw Exception('Booking ID is required');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/bookings/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'bookingId': bookingId.trim(),
          'notifyParticipants': notifyParticipants,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Cancellation request timed out.');
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 404) {
        throw Exception('Booking not found or already cancelled');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to cancel booking');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('connection')) {
        throw Exception('Cannot connect to server to cancel booking.');
      } else {
        throw Exception('Cancellation failed: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  // Enhanced email testing with detailed response
  Future<Map<String, dynamic>> testEmail(String email) async {
    try {
      if (!_isValidEmail(email)) {
        throw Exception('Invalid email format');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/bookings/simple-test-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim()}),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception('Email test timed out.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'messageId': data['messageId'],
          'message': data['message'] ?? 'Test email sent successfully',
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to send test email');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('connection')) {
        throw Exception('Cannot connect to email service.');
      } else {
        throw Exception('Email test failed: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  // NEW: Resend booking confirmation email
  Future<bool> resendConfirmationEmail({
    required String bookingId,
    required String email,
  }) async {
    try {
      if (bookingId.isEmpty) {
        throw Exception('Booking ID is required');
      }
      
      if (!_isValidEmail(email)) {
        throw Exception('Invalid email format');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/bookings/resend-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'bookingId': bookingId.trim(),
          'email': email.trim(),
        }),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception('Email resend request timed out.');
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 404) {
        throw Exception('Booking not found');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to resend confirmation email');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('connection')) {
        throw Exception('Cannot connect to email service.');
      } else {
        throw Exception('Email resend failed: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  // NEW: Check server health and booking service status
  Future<Map<String, dynamic>> getServiceHealth() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl.replaceAll('/api', '')}/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Health check timed out');
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server health check failed');
      }
    } catch (e) {
      throw Exception('Cannot check service health: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // NEW: Get all bookings with advanced filtering
  Future<Map<String, dynamic>> getAllBookings({
    int page = 1,
    int limit = 20,
    String? status, // 'available', 'booked', 'cancelled'
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      List<String> queryParams = [
        'page=$page',
        'limit=$limit',
      ];
      
      if (status != null && status.isNotEmpty) {
        queryParams.add('status=${status.trim()}');
      }
      if (fromDate != null) {
        queryParams.add('fromDate=${fromDate.toIso8601String()}');
      }
      if (toDate != null) {
        queryParams.add('toDate=${toDate.toIso8601String()}');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/bookings?${queryParams.join('&')}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timed out while fetching bookings.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'bookings': data['data'] ?? [],
          'total': data['total'] ?? 0,
          'page': data['page'] ?? 1,
          'pages': data['pages'] ?? 1,
          'count': data['count'] ?? 0,
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch bookings');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('connection')) {
        throw Exception('Cannot connect to server to fetch bookings.');
      } else {
        throw Exception('Error fetching bookings: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  // Private helper method for email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email.trim());
  }

  // NEW: Utility method to format booking for display
  static Map<String, String> formatBookingForDisplay(Map<String, dynamic> booking) {
    try {
      final date = DateTime.parse(booking['date']);
      final formattedDate = '${date.day}/${date.month}/${date.year}';
      
      return {
        'id': booking['_id'] ?? '',
        'date': formattedDate,
        'time': '${booking['startTime']} - ${booking['endTime']}',
        'status': booking['isBooked'] == true ? 'Booked' : 'Available',
        'creatorId': booking['creatorId'] ?? '',
        'smeId': booking['smeId'] ?? '',
        'questionsCount': (booking['questions'] as List?)?.length.toString() ?? '0',
      };
    } catch (e) {
      return {
        'id': booking['_id'] ?? '',
        'date': 'Invalid date',
        'time': 'Invalid time',
        'status': 'Unknown',
        'creatorId': '',
        'smeId': '',
        'questionsCount': '0',
      };
    }
  }
}