import 'package:flutter/material.dart';
import '../services/survey_service.dart';
import '../../booking/screens/booking_screen.dart';
import '../../../shared/widgets/fluid_background.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../sme/screens/sme_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _ideaController = TextEditingController();
  final AuthService _authService = AuthService();
  List<String> _questions = [];
  bool _isLoading = false;
  bool _isRegenerating = false;
  int? _regeneratingIndex;
  String _currentProductIdea = '';
  late AnimationController _loadingAnimationController;
  late Animation<double> _loadingAnimation;
  
  // SME Password - You can change this or make it configurable
  static const String _smePassword = "admin123";

  @override
  void initState() {
    super.initState();
    _loadingAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ideaController.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  void _generateSurvey() async {
    if (_ideaController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a product idea');
      return;
    }

    if (_ideaController.text.trim().length < 5) {
      _showErrorSnackBar('Please provide a more detailed product idea (at least 5 characters)');
      return;
    }

    setState(() {
      _isLoading = true;
      _currentProductIdea = _ideaController.text.trim();
    });

    _loadingAnimationController.repeat();

    try {
      final surveyService = SurveyService();
      final questions = await surveyService.generateSurvey(_currentProductIdea);
      
      setState(() {
        _questions = questions;
        _isLoading = false;
      });

      _loadingAnimationController.stop();
      _showSuccessSnackBar('🎉 AI generated ${questions.length} custom questions!');
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      _loadingAnimationController.stop();
      _showErrorSnackBar('Error generating survey: ${e.toString()}');
    }
  }

  Future<void> _regenerateQuestion(int questionIndex) async {
    if (_currentProductIdea.isEmpty) return;

    setState(() {
      _isRegenerating = true;
      _regeneratingIndex = questionIndex;
    });

    try {
      final surveyService = SurveyService();
      final newQuestion = await surveyService.regenerateQuestion(_currentProductIdea, questionIndex);
      
      setState(() {
        _questions[questionIndex] = newQuestion;
        _isRegenerating = false;
        _regeneratingIndex = null;
      });

      _showSuccessSnackBar('✨ Question ${questionIndex + 1} regenerated!');
      
    } catch (e) {
      setState(() {
        _isRegenerating = false;
        _regeneratingIndex = null;
      });
      
      _showErrorSnackBar('Failed to regenerate question: ${e.toString()}');
    }
  }

  void _navigateToBooking() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookingScreen(questions: _questions),
      ),
    );
  }

  void _showSMEPasswordDialog() {
    final TextEditingController passwordController = TextEditingController();
    bool isPasswordVisible = false;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Colors.green.shade700.withOpacity(0.3),
                  width: 1,
                ),
              ),
              title: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.green.shade700.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      color: Colors.green.shade400,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'SME Portal Access',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'This area is restricted to Subject Matter Experts only. Please enter the access password.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: errorText != null 
                            ? Colors.red.shade400 
                            : Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: TextField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter password',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      onSubmitted: (_) {
                        // Allow enter key to submit
                        _validateSMEPassword(passwordController.text, context);
                      },
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade400,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          errorText!,
                          style: TextStyle(
                            color: Colors.red.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (passwordController.text.isEmpty) {
                      setState(() {
                        errorText = 'Please enter a password';
                      });
                      return;
                    }
                    
                    if (passwordController.text == _smePassword) {
                      Navigator.of(context).pop();
                      _navigateToSMEDashboard();
                    } else {
                      setState(() {
                        errorText = 'Incorrect password. Please try again.';
                      });
                      passwordController.clear();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Verify Access',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _validateSMEPassword(String password, BuildContext dialogContext) {
    if (password == _smePassword) {
      Navigator.of(dialogContext).pop();
      _navigateToSMEDashboard();
    }
  }

  void _navigateToSMEDashboard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SMEDashboardScreen(),
      ),
    );
  }

  void _handleLogout() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      await _authService.logout();
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Logout failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _loadingAnimation,
      builder: (context, child) {
        return Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    color: Colors.blue.shade300,
                    strokeWidth: 3.0,
                  ),
                ),
                Icon(
                  Icons.psychology,
                  color: Colors.blue.shade300,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'AI is crafting your survey questions...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This may take 5-15 seconds on first use',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FluidBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced app header with SME Portal button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Outlaw',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'AI',
                            style: TextStyle(
                              color: Colors.blue.shade200,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // SME Portal Button with Password Protection
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: ElevatedButton.icon(
                            onPressed: _showSMEPasswordDialog,
                            icon: const Icon(Icons.business_center, size: 16, color: Colors.white),
                            label: const Text(
                              'SME Portal',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: const Size(0, 32),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: _isLoading ? null : _handleLogout,
                          tooltip: 'Logout',
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Loading state
                if (_isLoading) ...[
                  Expanded(
                    child: Center(
                      child: _buildLoadingIndicator(),
                    ),
                  ),
                ]
                
                // Title section
                else if (_questions.isEmpty) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Survey Generator',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your product idea below to generate custom survey questions powered by AI',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Text input section
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
                      controller: _ideaController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 7,
                      decoration: InputDecoration(
                        hintText: 'Describe your product idea in detail...\n\nExample: A mobile app that helps people find and book local fitness classes with real-time availability and reviews',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Generate button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generateSurvey,
                      icon: const Icon(Icons.psychology, color: Colors.white),
                      label: const Text(
                        'Generate AI Survey Questions',
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
                ]
                
                // Questions list
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Generated Questions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_questions.length} Questions',
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
                  
                  Expanded(
                    child: ListView.builder(
                      itemCount: _questions.length,
                      itemBuilder: (context, index) {
                        final isRegeneratingThis = _regeneratingIndex == index && _isRegenerating;
                        
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
                                  _questions[index],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Regenerate button
                              IconButton(
                                onPressed: isRegeneratingThis ? null : () => _regenerateQuestion(index),
                                icon: isRegeneratingThis 
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.blue.shade300,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      Icons.refresh,
                                      color: Colors.blue.shade300,
                                      size: 20,
                                    ),
                                tooltip: 'Regenerate this question',
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _navigateToBooking,
                          icon: const Icon(Icons.calendar_today, color: Colors.white),
                          label: const Text(
                            'Book Interview',
                            style: TextStyle(color: Colors.white),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _questions = [];
                              _ideaController.clear();
                              _currentProductIdea = '';
                            });
                          },
                          icon: Icon(Icons.add, color: Colors.blue.shade300),
                          label: Text(
                            'New Survey',
                            style: TextStyle(color: Colors.blue.shade300),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.blue.shade300),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}