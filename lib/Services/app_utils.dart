import 'package:flutter/material.dart';
import 'motivational_messages.dart';
import 'dart:math';

class AppUtils {
  static void showMotivationalPopup(BuildContext context) {
    // Randomly select a message from the list
    final random = Random();
    final message = motivationalMessages[random.nextInt(motivationalMessages.length)];

    // Show the message as a popup
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Motivational Message"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the popup
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}