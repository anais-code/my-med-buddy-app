import 'package:flutter/material.dart';
import 'package:my_med_buddy_app/Services/authentication.dart';
import 'signup_login.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});
  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  //declare obj of auth services class
  final AuthServices _authService = AuthServices();

  //method to use sign out from authentication.dart
  void _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    //navigates back to signup_login screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => SignupLoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFE3E3),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: GestureDetector(
                onTap: _signOut,
                child: Container(
                  padding: EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6565), Color(0xFFFF5050)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Center(
                    child: Text(
                      'Log Out',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFDFFEF),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
