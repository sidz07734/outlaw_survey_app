// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = 'http://localhost:5000'; // Use your server port
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: kIsWeb ? '112937558821-pkcrop2u0s2nvmv5vhf39jmt0bm6sj1q.apps.googleusercontent.com' : null,
  );

  // Standard login method
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final userData = json.decode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', userData['data']['token']);
      return userData['data'];
    } else {
      throw Exception('Failed to login: ${json.decode(response.body)['error']}');
    }
  }

  // Register method
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final userData = json.decode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', userData['data']['token']);
      return userData['data'];
    } else {
      throw Exception('Failed to register: ${json.decode(response.body)['error']}');
    }
  }

  // Logout method
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await _googleSignIn.signOut();
  }

  // Google Sign In - Advanced with token
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('User canceled Google sign-in');
        return null;
      }

      // Get auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Send the ID token to your backend
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/google/callback'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': googleAuth.idToken,
        }),
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        
        // Store the token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', userData['data']['token']);
        
        return userData['data'];
      } else {
        print('Failed to authenticate with Google: ${response.body}');
        
        // Try fallback method if token approach fails
        return signInWithGoogleLegacy(googleUser);
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }
  
  // Legacy fallback method
  Future<Map<String, dynamic>?> signInWithGoogleLegacy(GoogleSignInAccount googleUser) async {
    try {
      // Send user info directly to your backend
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'googleId': googleUser.id,
          'email': googleUser.email,
          'name': googleUser.displayName,
        }),
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        
        // Store the token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', userData['data']['token']);
        
        return userData['data'];
      } else {
        print('Failed with legacy Google auth: ${response.body}');
        throw Exception('Failed to authenticate with Google');
      }
    } catch (e) {
      print('Error with legacy Google sign-in: $e');
      return null;
    }
  }

  // Get current user from token
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      return null;
    }
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }
}