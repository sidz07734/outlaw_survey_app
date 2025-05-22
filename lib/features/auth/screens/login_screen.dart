import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          width: screenSize.width * 0.9,
          height: screenSize.height * 0.85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              // Left side with the beautiful gradient
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              Colors.purple.shade900,
                              Colors.purple.shade700,
                              Colors.pink.shade600, 
                              Colors.blue.shade700,
                            ],
                          ),
                        ),
                      ),
                      // Dark overlay to make the text more readable
                      Container(
                        color: Colors.black.withOpacity(0.5),
                      ),
                      // Content on left side
                      Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "A WISE QUOTE",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const Spacer(flex: 3),
                            const Text(
                              "Get\nEverything\nYou Want",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                            ),
                            const Spacer(flex: 1),
                            const Text(
                              "You can get everything you want if you work hard, trust the process, and stick to the plan.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const Spacer(flex: 2),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Right side with login form
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Cogie logo or your app logo
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.circle, size: 16),
                          SizedBox(width: 8),
                          Text(
                            "Outlaw",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black, // Updated to black
                            ),
                          ),
                        ],
                      ),
                      
                      const Spacer(flex: 2),
                      
                      // Welcome Back text
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Welcome Back",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.black, // Updated to black
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Enter your email and password to access your account",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      
                      const Spacer(flex: 2),
                      
                      // Email input
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Email",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.black, // Updated to black
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.black), // Updated to black
                              decoration: const InputDecoration(
                                hintText: "Enter your email",
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Password input
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Password",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.black, // Updated to black
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.black), // Updated to black
                              decoration: InputDecoration(
                                hintText: "Enter your password",
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                hintStyle: const TextStyle(color: Colors.grey),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Remember me and Forgot Password
                      Row(
                        children: [
                          // Remember me checkbox
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            activeColor: Colors.black, // Updated to black
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const Text(
                            "Remember me",
                            style: TextStyle(
                              color: Colors.black, // Updated to black
                            ),
                          ),
                          const Spacer(),
                          // Forgot password link
                          GestureDetector(
                            onTap: () {
                              // Handle forgot password
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Password reset functionality will be implemented soon')),
                              );
                            },
                            child: const Text(
                              "Forgot Password",
                              style: TextStyle(
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Sign In button
                      ElevatedButton(
                        onPressed: _isLoading ? null : () async {
                          if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter email and password')),
                            );
                            return;
                          }

                          try {
                            setState(() {
                              _isLoading = true;
                            });
                            
                            final authService = AuthService();
                            await authService.login(_emailController.text, _passwordController.text);
                            
                            Navigator.pushReplacementNamed(context, '/home');
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Login failed: ${e.toString()}')),
                            );
                          } finally {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "Sign In",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Google sign in button
                      OutlinedButton(
                        onPressed: _isLoading ? null : () async {
                          try {
                            setState(() {
                              _isLoading = true;
                            });
                            
                            final authService = AuthService();
                            await authService.signInWithGoogle();
                            
                            Navigator.pushReplacementNamed(context, '/home');
                          } catch (e) {
                            print("Google Sign-In Error: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Google sign in failed: ${e.toString()}')),
                            );
                          } finally {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google icon
                            const Icon(Icons.g_mobiledata, color: Colors.red, size: 24),
                            const SizedBox(width: 8),
                            const Text(
                              "Sign In with Google",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Sign up link
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black87, fontSize: 14),
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: "Sign Up",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pushReplacementNamed(context, '/signup');
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}