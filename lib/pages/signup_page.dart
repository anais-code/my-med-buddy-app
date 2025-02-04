import 'package:flutter/material.dart';
import 'package:my_med_buddy_app/Services/authentication.dart';
import 'package:my_med_buddy_app/pages/user_details_page.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  //initialise text controllers required input
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  //boolean method to ensure password is valid
  //i.e. min 8 chars, 1 uppercase, 1 symbol
  bool isValidPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  //sign up method
  Future<void> signup() async {
    //UI side check to ensure that all fields are filled out
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty) {
      //displays pop up message if all fields are not filled out
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill out all fields")),
      );
      return;
    }

    //checks to ensure that passwords entered by the user match
    //displays pop up message if they do not
    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Passwords must match")),
      );
      return;
    }

    //implementation of password validity check
    if (!isValidPassword(_passwordController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Password must be at least 8 characters, include an uppercase letter and a special character")));
      return;
    }

    //calls method from authentication.dart to sign up user using firebase auth
    String result = await AuthServices().signupUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );
    if (result == "success") {
      if (!mounted) return;
      //navigates to user_details_page after successful sign up
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const UserDetailsPage(),
        ),
      );
    } else {
      if (!mounted) return;
      //displays an error for user if sign up was unsuccessful
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result)));
    }
  }

  @override
  //disposes of controllers to help with in-app memory managment
  //NOTE -- good practice to implement with other in app controllers
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
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

              //sign up text
              Text(
                "Let's Get Started",
                style: TextStyle(
                  fontSize: 24,
                  color: Color(0xFF000000),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 50),

              //first and last name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFFDFFEF),
                            border: Border.all(color: Color(0xFFFF6565)),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20.0),
                            //textfield for first name
                            child: TextField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'First Name',
                                hintStyle: TextStyle(fontSize: 18),
                              ),
                              style: TextStyle(
                                  fontSize: 18, color: Color(0xFF545354)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFFDFFEF),
                            border: Border.all(color: Color(0xFFFF6565)),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20.0),
                            //textfield for last name
                            child: TextField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Last Name',
                                hintStyle: TextStyle(fontSize: 18),
                              ),
                              style: TextStyle(
                                  fontSize: 18, color: Color(0xFF545354)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              //email input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFFDFFEF),
                    border: Border.all(color: Color(0xFFFF6565)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  //textfield for email
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
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

              //passwords textfield
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
              SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFFDFFEF),
                    border: Border.all(color: Color(0xFFFF6565)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  //textfield for confirm password
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Confirm password',
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

              //Sign Up button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: GestureDetector(
                  //calls signup function
                  onTap: signup,
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
                        'Sign Up',
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
              SizedBox(height: 10),

              //login hyperlink
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account?",
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF000000),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: Text(
                      ' Login',
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
