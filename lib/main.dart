import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'pages/signup_login.dart';
import 'package:my_med_buddy_app/Services/notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  //init notifications
  Notifications notifications = Notifications();
  notifications.initNotification();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        //on start-up, app goes to sign up login main screen
        home: SignupLoginPage());
  }
}
