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

class _BookingScreenState extends State<BookingScreen> with TickerProviderStateMixin {
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  bool _isLoading = false;
  DateTime _focusedDay = DateTime.now();
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  int _currentYear = DateTime.now().year;
  int _selectedYear = DateTime.now().year;
  
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Enhanced time slots with availability simulation
  final List<Map<String, dynamic>> _timeSlots = [
    {'time': '9:00 AM - 10:00 AM', 'available': true},
    {'time': '10:00 AM - 11:00 AM', 'available': true},
    {'time': '11:00 AM - 12:00 PM', 'available': true},
    {'time': '1:00 PM - 2:00 PM', 'available': true},
    {'time': '2:00 PM - 3:00 PM', 'available': true},
    {'time': '3:00 PM - 4:00 PM', 'available': true},
  ];

  final List<int> _availableYears = [
    DateTime.now().year,
    DateTime.now().year + 1,
    DateTime.now().year + 2,
  ];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  bool _isDateAvailable(DateTime date) {
    // Prevent booking on weekends and past dates
    return date.isAfter(DateTime.now().subtract(const Duration(days: 1))) &&
           date.weekday != DateTime.saturday &&
           date.weekday != DateTime.sunday;
  }

  void _bookInterview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null || _selectedTimeSlot == null) {
      _showErrorSnackBar('Please select a date and time slot');
      return;
    }

    if (!_isDateAvailable(_selectedDate!)) {
      _showErrorSnackBar('Selected date is not available for booking');
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showErrorSnackBar('Please enter a valid email address');
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
        email: _emailController.text.trim(),
        questions: widget.questions,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      _showSuccessSnackBar('🎉 Interview slot created and confirmation email sent!');
      
      // Navigate to confirmation screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingConfirmationScreen(
            questions: widget.questions,
            selectedDate: _selectedDate!,
            selectedTimeSlot: _selectedTimeSlot!,
            email: _emailController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      _showErrorSnackBar('Booking failed: ${e.toString()}');
    }
  }

  void _changeYear(int year) {
    setState(() {
      _selectedYear = year;
      _focusedDay = DateTime(year, _focusedDay.month, 1);
      _selectedDate = null;
      _selectedTimeSlot = null;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          _buildStepIndicator(1, 'Date', _selectedDate != null),
          Expanded(child: Container(height: 2, color: Colors.white.withOpacity(0.3))),
          _buildStepIndicator(2, 'Time', _selectedTimeSlot != null),
          Expanded(child: Container(height: 2, color: Colors.white.withOpacity(0.3))),
          _buildStepIndicator(3, 'Email', _emailController.text.isNotEmpty),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool completed) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? Colors.green.shade600 : Colors.white.withOpacity(0.3),
          ),
          child: Center(
            child: completed
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    step.toString(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FluidBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enhanced header
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Book SME Interview',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${widget.questions.length} questions prepared',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Progress indicator
                    _buildProgressIndicator(),
                    
                    const SizedBox(height: 20),
                    
                    // Description with tips
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade300.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_outline, color: Colors.blue.shade300, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Booking Tips',
                                style: TextStyle(
                                  color: Colors.blue.shade300,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Select a date and time for your expert interview\n'
                            '• Weekends are not available for booking\n'
                            '• You\'ll receive email confirmation with questions',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
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
                            underline: Container(),
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
                    
                    const SizedBox(height: 16),
                    
                    // Enhanced Calendar
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
                          availableCalendarFormats: const {
                            CalendarFormat.month: 'Month',
                          },
                          selectedDayPredicate: (day) {
                            return _selectedDate != null && isSameDay(_selectedDate!, day);
                          },
                          enabledDayPredicate: _isDateAvailable,
                          onDaySelected: (selectedDay, focusedDay) {
                            if (_isDateAvailable(selectedDay)) {
                              setState(() {
                                _selectedDate = selectedDay;
                                _focusedDay = focusedDay;
                                _selectedTimeSlot = null; // Reset time selection
                              });
                              _animationController.forward();
                            }
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                          },
                          calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: Colors.blue.shade700.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: Colors.blue.shade700,
                              shape: BoxShape.circle,
                            ),
                            disabledDecoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            defaultTextStyle: const TextStyle(color: Colors.white),
                            weekendTextStyle: TextStyle(color: Colors.red.shade300),
                            todayTextStyle: const TextStyle(color: Colors.white),
                            selectedTextStyle: const TextStyle(color: Colors.white),
                            disabledTextStyle: TextStyle(color: Colors.grey.shade600),
                            outsideTextStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                          ),
                          headerStyle: HeaderStyle(
                            titleCentered: true,
                            formatButtonVisible: false,
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
                    
                    const SizedBox(height: 24),
                    
                    // Time slots (animated appearance)
                    if (_selectedDate != null) ...[
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Available Time Slots',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade700.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    DateFormat('MMM d, yyyy').format(_selectedDate!),
                                    style: TextStyle(
                                      color: Colors.green.shade200,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Enhanced time slots grid
                            GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 3.2,
                              ),
                              itemCount: _timeSlots.length,
                              itemBuilder: (context, index) {
                                final slot = _timeSlots[index];
                                final timeSlot = slot['time'] as String;
                                final isAvailable = slot['available'] as bool;
                                final isSelected = _selectedTimeSlot == timeSlot;
                                
                                return GestureDetector(
                                  onTap: isAvailable ? () {
                                    setState(() {
                                      _selectedTimeSlot = timeSlot;
                                    });
                                  } : null,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: !isAvailable 
                                          ? Colors.grey.withOpacity(0.3)
                                          : isSelected 
                                              ? Colors.blue.shade700 
                                              : Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: !isAvailable
                                            ? Colors.grey.withOpacity(0.5)
                                            : isSelected 
                                                ? Colors.blue.shade300 
                                                : Colors.white.withOpacity(0.2),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Center(
                                          child: Text(
                                            timeSlot,
                                            style: TextStyle(
                                              color: !isAvailable
                                                  ? Colors.grey.shade600
                                                  : isSelected 
                                                      ? Colors.white 
                                                      : Colors.white.withOpacity(0.8),
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              fontSize: 13,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        if (!isAvailable)
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: Icon(
                                              Icons.block,
                                              color: Colors.red.shade400,
                                              size: 16,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Enhanced email input
                            const Text(
                              'Contact Information',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: TextFormField(
                                controller: _emailController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  hintText: 'Enter your email for confirmation',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                  border: InputBorder.none,
                                  prefixIcon: Icon(Icons.email_outlined, color: Colors.white.withOpacity(0.7)),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Email is required';
                                  }
                                  if (!_isValidEmail(value.trim())) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Enhanced book button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _bookInterview,
                                icon: _isLoading 
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.0,
                                        ),
                                      )
                                    : const Icon(Icons.event_available, color: Colors.white),
                                label: Text(
                                  _isLoading ? 'Booking Interview...' : 'Book Interview',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  disabledBackgroundColor: Colors.blue.shade700.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Enhanced Confirmation Screen (keeping existing functionality but with better styling)
class BookingConfirmationScreen extends StatelessWidget {
  final List<String> questions;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final String email;

  const BookingConfirmationScreen({
    Key? key,
    required this.questions,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.email,
  }) : super(key: key);

  void _logout(BuildContext context) async {
    try {
      bool confirm = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        final authService = AuthService();
        await authService.logout();
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
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
                  // Header with back and logout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () => _logout(context),
                        tooltip: "Logout",
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Success animation
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  const Center(
                    child: Text(
                      'Interview Successfully Scheduled!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Center(
                    child: Text(
                      'We\'ve sent you a confirmation email with all the details',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Booking details card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade700.withOpacity(0.3),
                          Colors.blue.shade800.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blue.shade300.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.blue.shade300),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.blue.shade300),
                            const SizedBox(width: 12),
                            Text(
                              selectedTimeSlot,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.email_outlined, color: Colors.blue.shade300),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                email,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Icon(Icons.quiz_outlined, color: Colors.white.withOpacity(0.8)),
                      const SizedBox(width: 8),
                      Text(
                        'Your Survey Questions (${questions.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Questions list
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
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
                             width: 32,
                             height: 32,
                             alignment: Alignment.center,
                             decoration: BoxDecoration(
                               gradient: LinearGradient(
                                 colors: [Colors.blue.shade600, Colors.blue.shade800],
                               ),
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
                           const SizedBox(width: 16),
                           Expanded(
                             child: Text(
                               questions[index],
                               style: const TextStyle(
                                 color: Colors.white,
                                 fontSize: 16,
                                 height: 1.4,
                               ),
                             ),
                           ),
                         ],
                       ),
                     );
                   },
                 ),
                 
                 const SizedBox(height: 32),
                 
                 // Action buttons
                 Row(
                   children: [
                     Expanded(
                       child: ElevatedButton.icon(
                         onPressed: () {
                           Navigator.popUntil(context, (route) => route.isFirst);
                         },
                         icon: const Icon(Icons.home, color: Colors.white),
                         label: const Text(
                           'Return Home',
                           style: TextStyle(
                             color: Colors.white,
                             fontSize: 16,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.blue.shade700,
                           padding: const EdgeInsets.symmetric(vertical: 16),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(12),
                           ),
                         ),
                       ),
                     ),
                     const SizedBox(width: 16),
                     Expanded(
                       child: OutlinedButton.icon(
                         onPressed: () => _logout(context),
                         icon: Icon(Icons.logout, color: Colors.red.shade300),
                         label: Text(
                           'Logout',
                           style: TextStyle(
                             color: Colors.red.shade300,
                             fontSize: 16,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                         style: OutlinedButton.styleFrom(
                           side: BorderSide(color: Colors.red.shade300),
                           padding: const EdgeInsets.symmetric(vertical: 16),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(12),
                           ),
                         ),
                       ),
                     ),
                   ],
                 ),
                 
                 const SizedBox(height: 40),
               ],
             ),
           ),
         ),
       ),
     ),
   );
 }
}