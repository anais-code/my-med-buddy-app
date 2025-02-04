import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_med_buddy_app/pages/schedule_page.dart';

class UserDetailsPage extends StatefulWidget {
  const UserDetailsPage({super.key});
  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  //initialise controller for pre-exisiting conditions
  final _conditionsController = TextEditingController();

  //vars to collect user input
  String? userAge;
  String? userGender;
  String? userHeight;
  String? userWeight;

  //declare values for user age
  final List<String> ageOptions =
      List.generate(100, (index) => (index + 1).toString());
  //declare values for gender
  final List<String> genderOptions = ['Male', 'Female', 'Other'];
  //declare values for height in cm
  final List<String> heightOptions =
      List.generate(250, (index) => "${index + 50} cm");
  //declare values for weight in lbs
  final List<String> weightOptions =
      List.generate(400, (index) => "${index + 20} lbs");

  //method to save user details to firestore db
  Future<void> saveDetails() async {
    //uses firebase to get current user
    User? user = FirebaseAuth.instance.currentUser;
    //if user exists, update their null info with their input based on user id
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .update({
          'age': userAge,
          'gender': userGender,
          'height': userHeight,
          'weight': userWeight,
          'conditions': _conditionsController.text.trim(),
        });

        if (!mounted) return;

        //if successful, go to schedule page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SchedulePage()),
        );
        //else display error
      } catch (err) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $err')));
      }
    }
  }

  @override
  //dispose of controller
  void dispose() {
    _conditionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFE3E3),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                //logo of mmb mascot smiling
                SizedBox(height: 60),
                Image.asset(
                  'assets/images/mmb_smiling.png',
                  height: 200,
                ),
                SizedBox(height: 40),

                //details text
                Text(
                  "Let's get some more details",
                  style: TextStyle(
                    fontSize: 24,
                    color: Color(0xFF000000),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 50),

                /*age and gender pickers make up one row
                height and weight pickers make up another row
              ``textfield for pre-exisitng conditions are below them*/

                //age picker
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
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
                              padding: const EdgeInsets.only(left: 10.0),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  hint: Text("Select Age",
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.grey)),
                                  value: userAge,
                                  isExpanded: true,
                                  items: ageOptions.map((String age) {
                                    return DropdownMenuItem<String>(
                                      value: age,
                                      child: Text(age,
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: Color(0xFF545354))),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      userAge = newValue;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      //gender picker
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
                              padding: const EdgeInsets.only(left: 10.0),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  hint: Text("Choose Gender",
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.grey)),
                                  value: userGender,
                                  isExpanded: true,
                                  items: genderOptions.map((String gender) {
                                    return DropdownMenuItem<String>(
                                      value: gender,
                                      child: Text(gender,
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: Color(0xFF545354))),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      userGender = newValue;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                //height picker
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
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
                              padding: const EdgeInsets.only(left: 10.0),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  hint: Text("Enter Height (cm)",
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.grey)),
                                  value: userHeight,
                                  isExpanded: true,
                                  items: heightOptions.map((String height) {
                                    return DropdownMenuItem<String>(
                                      value: height,
                                      child: Text(height,
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: Color(0xFF545354))),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      userHeight = newValue;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      //weight picker
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
                              padding: const EdgeInsets.only(left: 10.0),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  hint: Text("Enter Weight (lbs)",
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.grey)),
                                  value: userWeight,
                                  isExpanded: true,
                                  items: weightOptions.map((String weight) {
                                    return DropdownMenuItem<String>(
                                      value: weight,
                                      child: Text(weight,
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: Color(0xFF545354))),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      userWeight = newValue;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                //pre-existing conditions textfield
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFFDFFEF),
                      border: Border.all(color: Color(0xFFFF6565)),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextField(
                        controller: _conditionsController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText:
                              'Enter preexisting conditions (comma-separated)',
                          hintStyle: TextStyle(fontSize: 18),
                        ),
                        style:
                            TextStyle(fontSize: 18, color: Color(0xFF545354)),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40),

                //submit button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: GestureDetector(
                    onTap: saveDetails,
                    child: Container(
                      padding: EdgeInsets.all(25),
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
                          'Save Details',
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
        ),
      ),
    );
  }
}
