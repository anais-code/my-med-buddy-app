import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_page.dart';

class SignupLoginPage extends StatefulWidget {
  const SignupLoginPage({super.key});
  //const SignupLoginPage() : super();
  @override
  State<SignupLoginPage> createState() => _SignupLoginPageState();
}

class _SignupLoginPageState extends State<SignupLoginPage> {
  // Navigate to the LoginPage when login button is pressed
  void _goToLoginPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  // Navigate to the LoginPage when login button is pressed
  void _goToSignupPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignupPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    //design of UI starts here
    return Scaffold(
      //for hex colours use format (0xFF123456)
      backgroundColor: Color(0xFFFFE3E3),
      body: Column(
        children: [
          SizedBox(height: 80),
          //MMB icon
          Image.asset(
            'assets/images/mmb_logo.png',
            height: 350,
            width: 350,
          ),
          SizedBox(height: 150),

          //login button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: GestureDetector(
              onTap: _goToLoginPage,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFF6565), //left colour
                      Color(0xFFFF5050) //right colour
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Center(
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: Color(0xFFFDFFEF),
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 50),

          //sign up button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: GestureDetector(
              onTap: _goToSignupPage,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFF6565), //left colour
                      Color(0xFFFF5050) //right colour
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Center(
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Color(0xFFFDFFEF),
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
