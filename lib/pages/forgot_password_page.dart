import 'package:flutter/material.dart';
import 'package:my_med_buddy_app/Services/authentication.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // Text controller for email input
  final _emailController = TextEditingController();
  // AuthServices instance for password reset
  final AuthServices _authServices = AuthServices();
  // Loading state
  bool _isLoading = false;

  // Method to handle password reset
  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Call the password reset method from AuthServices
      String result = await _authServices.resetPassword(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );

      // Navigate back to the login page after successful reset
      if (result == "Password reset email sent") {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reset email: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE3E3),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // MMB Mascot
                const SizedBox(height: 60),
                Image.asset(
                  'assets/images/mmb_mascot.png',
                  height: 200,
                ),
                const SizedBox(height: 40),

                // Title
                const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 24,
                    color: Color(0xFF000000),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Subtitle
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25.0),
                  child: Text(
                    'Enter your email address to reset your password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF545354),
                    ),
                  ),
                ),
                const SizedBox(height: 50),

                // Email Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDFFEF),
                      border: Border.all(color: const Color(0xFFFF6565)),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter email',
                          hintStyle: TextStyle(fontSize: 18),
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF545354),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Reset Password Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: GestureDetector(
                    onTap: _isLoading ? null : _resetPassword,
                    child: Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6565), Color(0xFFFF5050)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(
                          color: Color(0xFFFDFFEF),
                        )
                            : const Text(
                          'Reset Password',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFDFFEF),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Back to Login Link
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Go back to the login page
                  },
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF5050),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}