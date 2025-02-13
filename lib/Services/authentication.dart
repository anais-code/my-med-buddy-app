import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthServices {
  //declare instances of firestore and auth to be used for login and sign up
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //method to sign a user up
  Future<String> signupUser({
    //declare required vars for sign up
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    String result = "An error occurred during Sign Up. Please try again.";
    try {
      //ensures that all fields are filled out by the user before attempting sign up
      if (email.isNotEmpty &&
          password.isNotEmpty &&
          firstName.isNotEmpty &&
          lastName.isNotEmpty) {
        //use firebase auth to sign up user with email and password
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        //save user details (excl. password) in Firestore db
        await _firestore.collection("users").doc(cred.user!.uid).set({
          'firstName': firstName,
          'lastName': lastName,
          'uid': cred.user!.uid,
          'email': email,
          //initialise as null values as they will be changed in user_details_page.dart
          'age': null,
          'gender': null,
          'height': null,
          'weight': null,
        });

        result = "success";
      }
    } catch (err) {
      return err.toString();
    }
    return result;
  }

  //method to log in a user
  Future<String> loginUser({
    //declare vars needed for login
    required String email,
    required String password,
  }) async {
    String result = "An error occurred during Login. Please try again.";
    try {
      //ensures that both fields are filled out before login is attempted
      if (email.isNotEmpty && password.isNotEmpty) {
        //use firebase auth to login user with email and password
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        result = "success";
      } else {
        //error message if fields are not filled out correctly
        result = "Please fill out all fields";
      }
    } catch (err) {
      return err.toString();
    }
    return result;
  }

  //boolean method to determine if all user details were captured
  Future<bool> hasUserCompletedDetails() async {
    //gets the current user based on session
    User? user = _auth.currentUser;
    //gets the user id if the user exists
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      //checks to determine if user has already completed user_details_page form
      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>;
        return data['age'] != null &&
            data['gender'] != null &&
            data['height'] != null &&
            data['weight'] != null;
      }
    }
    //returns false to navigate to user_details_page after intial sign up
    return false;
  }

  //method to sign user out
  signOut() async {
    await _auth.signOut();
  }

  //method to reset user password
  Future<String> resetPassword({required String email}) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return "Password reset email sent";
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Failed to send reset email";
    }
  }
}
