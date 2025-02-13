import 'package:flutter/material.dart';
import 'package:my_med_buddy_app/Services/authentication.dart';
import 'signup_page.dart';
import 'schedule_page.dart';
import 'user_details_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //initialise text controllers for input
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  //declare var for auth services class -- done because login is static
  final AuthServices _authServices = AuthServices();
  bool _isLoading = false;

  //method for user login
  Future login() async {
    setState(() {
      _isLoading = true;
    });

    //calls method from authentication.dart to sign up user using firebase auth
    String result = await _authServices.loginUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (result == "success") {
      //checks to ensure that user has filled out form in user_details_page
      bool detailsCompleted = await _authServices.hasUserCompletedDetails();

      if (!mounted) return;

      //if they have, user bypasses that page and goes straight to schedule page aka homescreen
      if (detailsCompleted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SchedulePage()),
        );
        //else they are taken to user_details_page
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UserDetailsPage()),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }

  @override
  //disposes of controllers
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFE3E3),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(children: [
              //mmb mascot
              SizedBox(height: 60),
              Image.asset(
                'assets/images/mmb_mascot.png',
                height: 200,
              ),
              SizedBox(height: 40),

              //welcome back text
              Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 24,
                  color: Color(0xFF000000),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 50),

              //email input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFFDFFEF),
                    border: Border.all(color: Color(0xFFFF6565)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    //textfield for email
                    child: TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter email',
                        hintStyle: TextStyle(fontSize: 18),
                      ),
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF545354),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              //password textfield
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFFDFFEF),
                    border: Border.all(color: Color(0xFFFF6565)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    //textfield for password
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter password',
                        hintStyle: TextStyle(fontSize: 18),
                      ),
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF545354),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),

              //forgot password hyperlink
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                            );
                          },
                          child: Text("Forgot Password?",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF545354),
                                fontWeight: FontWeight.bold,
                              ))))),
              SizedBox(height: 20),

              //login button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: GestureDetector(
                  onTap: _isLoading ? null : login,
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
                      //progress indicator for login
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Color(0xFFFDFFEF),
                            )
                          : const Text(
                              'Login',
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
              SizedBox(height: 10),

              //sign up hyperlink
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF000000),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SignupPage(),
                        ),
                      );
                    },
                    child: Text(
                      ' Sign Up',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF5050),
                      ),
                    ),
                  ),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
