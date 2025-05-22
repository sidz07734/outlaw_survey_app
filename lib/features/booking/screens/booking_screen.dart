import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/booking_service.dart';
import '../../../shared/widgets/fluid_background.dart';
import '../../auth/services/auth_service.dart';

class BookingScreen extends StatefulWidget {
  final List<String> questions;
  
  const BookingScreen({Key? key, required this.questions}) : super(key: key);

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  bool _isLoading = false;
  DateTime _focusedDay = DateTime.now();
  // Fixed to month view only
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  int _currentYear = DateTime.now().year;
  int _selectedYear = DateTime.now().year;
  
  // Add email controller
  final TextEditingController _emailController = TextEditingController();
  
  // Define available time slots
  final List<String> _timeSlots = [
    '9:00 AM - 10:00 AM',
    '10:00 AM - 11:00 AM',
    '11:00 AM - 12:00 PM',
    '1:00 PM - 2:00 PM',
    '2:00 PM - 3:00 PM',
    '3:00 PM - 4:00 PM',
  ];

  // List of years to select from
  final List<int> _availableYears = [
    DateTime.now().year,
    DateTime.now().year + 1,
    DateTime.now().year + 2,
  ];
  
  @override
  void dispose() {
    // Clean up controller when the widget is disposed
    _emailController.dispose();
    super.dispose();
  }

  void _bookInterview() async {
    if (_selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time slot')),
      );
      return;
    }
    
    // Validate email
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email for confirmation')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final bookingService = BookingService();
      final times = _selectedTimeSlot!.split(' - ');
      
      final booking = await bookingService.createTimeSlot(
        creatorId: 'user123', // Mock user ID
        date: _selectedDate!,
        startTime: times[0],
        endTime: times[1],
        email: _emailController.text, // Add email
        questions: widget.questions, // Add questions
      );
      
      setState(() {
        _isLoading = false;
      });
      
      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Interview slot created and confirmation email sent!')),
      );
      
      // Navigate to confirmation screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingConfirmationScreen(
            questions: widget.questions,
            selectedDate: _selectedDate!,
            selectedTimeSlot: _selectedTimeSlot!,
            email: _emailController.text, // Pass email to confirmation screen
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // Method to change year
  void _changeYear(int year) {
    setState(() {
      _selectedYear = year;
      // Update focused day to the same day in the new year
      _focusedDay = DateTime(year, _focusedDay.month, 1);
      // Clear selected date when changing years
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FluidBackground(
        child: SafeArea(
          // Use SingleChildScrollView to enable scrolling for the entire screen
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar with back button
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Book SME Interview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Description
                  Text(
                    'Select a date and time for your interview with a Subject Matter Expert.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Year Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Select Year: ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: DropdownButton<int>(
                          value: _selectedYear,
                          dropdownColor: const Color(0xFF1A1A2E),
                          underline: Container(), // Remove underline
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                          style: const TextStyle(color: Colors.white),
                          onChanged: (int? newValue) {
                            if (newValue != null) {
                              _changeYear(newValue);
                            }
                          },
                          items: _availableYears.map<DropdownMenuItem<int>>((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text(value.toString()),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Calendar view (with limited height to ensure it doesn't take too much space)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: TableCalendar(
                        firstDay: DateTime(_selectedYear, 1, 1),
                        lastDay: DateTime(_selectedYear, 12, 31),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        // Disable changing calendar format
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Month',
                        },
                        selectedDayPredicate: (day) {
                          return _selectedDate != null && isSameDay(_selectedDate!, day);
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDate = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                        calendarStyle: CalendarStyle(
                          // Today's decoration
                          todayDecoration: BoxDecoration(
                            color: Colors.blue.shade700.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          // Selected day decoration
                          selectedDecoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            shape: BoxShape.circle,
                          ),
                          // Default text style
                          defaultTextStyle: const TextStyle(color: Colors.white),
                          // Weekend text style
                          weekendTextStyle: const TextStyle(color: Colors.white70),
                          // Today's text style
                          todayTextStyle: const TextStyle(color: Colors.white),
                          // Selected day's text style
                          selectedTextStyle: const TextStyle(color: Colors.white),
                          // Outside days text style (days from other months)
                          outsideTextStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                          // Marker decoration
                          markerDecoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: HeaderStyle(
                          titleCentered: true,
                          formatButtonVisible: false, // Hide format button
                          leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
                          rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
                          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        daysOfWeekStyle: const DaysOfWeekStyle(
                          weekdayStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          weekendStyle: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Time slots (only visible when a date is selected)
                  if (_selectedDate != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Time Slot',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Show selected date
                        Text(
                          'Selected: ${DateFormat('MMM d, yyyy').format(_selectedDate!)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    
                    // Time slots grid (not in an Expanded widget to allow scrolling)
                    GridView.builder(
                      // Make the grid non-scrollable (parent ScrollView will handle scrolling)
                      physics: const NeverScrollableScrollPhysics(),
                      // Set a fixed height based on the number of rows needed
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.0,
                      ),
                      itemCount: _timeSlots.length,
                      itemBuilder: (context, index) {
                        final timeSlot = _timeSlots[index];
                        final isSelected = _selectedTimeSlot == timeSlot;
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTimeSlot = timeSlot;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue.shade700 : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? Colors.blue.shade300 : Colors.white.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              timeSlot,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Email input field - ADD THIS NEW SECTION
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          hintText: 'Enter your email for confirmation',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.email, color: Colors.white.withOpacity(0.7)),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Book button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _bookInterview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.blue.shade700.withOpacity(0.5),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.0,
                                ),
                              )
                            : const Text(
                                'Book Interview',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40), // Add extra space at the bottom for better scrolling
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Confirmation Screen
class BookingConfirmationScreen extends StatelessWidget {
  final List<String> questions;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final String email; // Added email parameter

  const BookingConfirmationScreen({
    Key? key,
    required this.questions,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.email, // Required email
  }) : super(key: key);

  // Logout function
  void _logout(BuildContext context) async {
    try {
      // Show a confirmation dialog
      bool confirm = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: const Text(
              "Confirm Logout",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "Are you sure you want to log out?",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  "Logout",
                  style: TextStyle(color: Colors.blue.shade300),
                ),
              ),
            ],
          );
        },
      ) ?? false;

      if (confirm) {
        // Call logout from your auth service
        final authService = AuthService();
        await authService.logout();
        
        // Navigate to login screen and clear all previous routes
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FluidBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar with back button and logout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      // Add logout button
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () => _logout(context),
                        tooltip: "Logout",
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Success icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.green,
                        size: 50,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  const Center(
                    child: Text(
                      'Interview Scheduled!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Show booking details
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Date: ${DateFormat('MMMM d, yyyy').format(selectedDate)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Time: $selectedTimeSlot',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Add email display
                          Text(
                            'Confirmation sent to: $email',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  const Text(
                    'Your Survey Questions:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Questions list with fixed height
                  ListView.builder(
                    shrinkWrap: true, // Important for nesting in SingleChildScrollView
                    physics: const NeverScrollableScrollPhysics(), // Disable scrolling for this list
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade700,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                questions[index],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Action buttons
                  Column(
                    children: [
                      // Return home button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.popUntil(context, (route) => route.isFirst);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Return to Home',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Logout button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _logout(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40), // Extra padding at bottom
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}