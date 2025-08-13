import 'package:flutter/material.dart';
import 'package:omahwajajanwatir/screen/login.dart';
import '../services/service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false; // State for loading indicator

  void _register() async {
    // Basic validation
    if (_usernameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill all fields')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      final response = await _apiService.register(
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
      );

      // Assuming `ApiService.register` already handles JSON decoding.
      // If the response is successful, it should contain a `user_id`.
      if (response.containsKey('user_id') && response['user_id'] != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration successful!')),
          );
          Navigator.pop(context);
        }
      } else {
        // Handle specific error messages from the backend
        String errorMessage = response['error'] ?? 'Registration failed. Please try again.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    } catch (e) {
      // Catch network-related errors like ClientException
      print('Error during registration: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred. Please check your connection and try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/main/bg_auth.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 90, right: 0, left: 0,
            child: Image.asset(
              'assets/main/logo_app.png',
              height: 200,
            ),
          ),
          // Foreground content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 30),
                Container(
                  margin: EdgeInsets.fromLTRB(50, 50, 50, 50),
                  child: Column(
                    children: [
                      // Username Field
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                          ),
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: Colors.white24,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                        ),
                      ),
                      SizedBox(height: 10),
                      // Email Field
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                          ),
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: Colors.white24,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                        ),
                      ),
                      SizedBox(height: 10),
                      // Password Field
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                          ),
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: Colors.white24,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        obscureText: true,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                _isLoading
                    ? CircularProgressIndicator(color: Colors.purple)
                    : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                        ),
                        child: Text(
                          'Register',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: Text(
                    'Sudah punya akun? Login',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          // Footer text
          Container(
            padding: EdgeInsets.only(bottom: 10.0),
            alignment: Alignment.bottomCenter,
            child: Text(
              'Made with ❤️ by Dindra',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}