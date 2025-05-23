import 'dart:convert';
import 'package:http/http.dart' as http;

class SMEService {
  final String baseUrl = 'http://localhost:5000/api';

  // Get available slots for SMEs to book
  Future<List<Map<String, dynamic>>> getAvailableSlots() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/available'),
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
        
        // Filter out past slots and ensure they're not already booked
        final now = DateTime.now();
        return slots.where((slot) {
          try {
            final slotDate = DateTime.parse(slot['date']);
            final isNotBooked = slot['isBooked'] != true;
            final isFuture = slotDate.isAfter(now.subtract(const Duration(days: 1)));
            return isNotBooked && isFuture;
          } catch (e) {
            return false;
          }
        }).toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch available slots');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('connection')) {
        throw Exception('Cannot connect to server. Please check your internet connection.');
      } else {
        throw Exception('Error fetching available slots: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  // Book a slot as an SME
  Future<Map<String, dynamic>> bookSlot({
    required String slotId,
    required String smeId,
    required String email,
    List<String>? questions,
  }) async {
    try {
      if (slotId.isEmpty || smeId.isEmpty || email.isEmpty) {
        throw Exception('Missing required booking information');
      }

      if (!_isValidEmail(email)) {
        throw Exception('Invalid email format');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/bookings/book'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': slotId.trim(),
          'smeId': smeId.trim(),
          'email': email.trim(),
          'questions': questions,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Booking request timed out. Please try again.');
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
          errorMessage = 'This time slot has just been booked by someone else. Please select another slot.';
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
      } else {
        throw Exception('Booking failed: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  // Get SME's booked interviews
  Future<List<Map<String, dynamic>>> getMyBookings(String smeId) async {
    try {
      if (smeId.isEmpty) {
        throw Exception('SME ID is required');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/bookings/sme/${smeId.trim()}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timed out while fetching your bookings.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bookings = List<Map<String, dynamic>>.from(data['data'] ?? []);
        
        // Sort by date (most recent first)
        bookings.sort((a, b) {
          try {
            final dateA = DateTime.parse(a['date']);
            final dateB = DateTime.parse(b['date']);
            return dateB.compareTo(dateA);
          } catch (e) {
            return 0;
          }
        });
        
        return bookings;
      } else if (response.statusCode == 404) {
        return []; // No bookings found - return empty list
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch your bookings');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('connection')) {
        throw Exception('Cannot connect to server to fetch your bookings.');
      } else {
        throw Exception('Error fetching your bookings: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  // Cancel a booking (if SME needs to cancel)
  Future<bool> cancelMyBooking(String bookingId) async {
    try {
      if (bookingId.isEmpty) {
        throw Exception('Booking ID is required');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/bookings/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'bookingId': bookingId.trim(),
          'notifyParticipants': true,
        }),
      ).timeout(
        const Duration(seconds: 20),
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

  // Get booking statistics for SME
  Future<Map<String, dynamic>> getBookingStats(String smeId) async {
    try {
      if (smeId.isEmpty) {
        throw Exception('SME ID is required');
      }

      final bookings = await getMyBookings(smeId);
      final now = DateTime.now();
      
      int totalBookings = bookings.length;
      int upcomingBookings = 0;
      int completedBookings = 0;
      
      for (var booking in bookings) {
        try {
          final bookingDate = DateTime.parse(booking['date']);
          if (bookingDate.isAfter(now)) {
            upcomingBookings++;
          } else {
            completedBookings++;
          }
        } catch (e) {
          // Skip invalid dates
        }
      }
      
      return {
        'total': totalBookings,
        'upcoming': upcomingBookings,
        'completed': completedBookings,
        'thisMonth': bookings.where((booking) {
          try {
            final bookingDate = DateTime.parse(booking['date']);
            return bookingDate.month == now.month && bookingDate.year == now.year;
          } catch (e) {
            return false;
          }
        }).length,
      };
    } catch (e) {
      throw Exception('Error calculating booking statistics: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // Email validation helper
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email.trim());
  }

  // Format booking for display
  static Map<String, String> formatBookingForDisplay(Map<String, dynamic> booking) {
    try {
      final date = DateTime.parse(booking['date']);
      final formattedDate = '${date.day}/${date.month}/${date.year}';
      final dayName = _getDayName(date.weekday);
      
      return {
        'id': booking['_id'] ?? '',
        'date': formattedDate,
        'dayName': dayName,
        'fullDate': '$dayName, $formattedDate',
        'time': '${booking['startTime']} - ${booking['endTime']}',
        'startTime': booking['startTime'] ?? '',
        'endTime': booking['endTime'] ?? '',
        'creatorId': booking['creatorId'] ?? '',
        'questionsCount': (booking['questions'] as List?)?.length.toString() ?? '0',
        'status': booking['isBooked'] == true ? 'Booked' : 'Available',
      };
    } catch (e) {
      return {
        'id': booking['_id'] ?? '',
        'date': 'Invalid date',
        'dayName': 'Unknown',
        'fullDate': 'Invalid date',
        'time': 'Invalid time',
        'startTime': '',
        'endTime': '',
        'creatorId': '',
        'questionsCount': '0',
        'status': 'Unknown',
      };
    }
  }

  // Helper method to get day name
  static String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
}