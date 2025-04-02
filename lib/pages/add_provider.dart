import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddProviderPage extends StatefulWidget {
  const AddProviderPage({super.key});
  @override
  State<AddProviderPage> createState() => _AddProviderPageState();
}

class _AddProviderPageState extends State<AddProviderPage> {
  //key to manage the form state
  final _formKey = GlobalKey<FormState>();

  //controllers for input related to provider
  final _providerNameController = TextEditingController();
  final _providerSpecialtyController = TextEditingController();
  final _providerNumberController = TextEditingController();
  final _providerEmailController = TextEditingController();
  final _conditionTreatedController = TextEditingController();

  @override
  //disposes of controllers to help with in-app memory managment
  void dispose() {
    _providerNameController.dispose();
    _providerSpecialtyController.dispose();
    _providerNumberController.dispose();
    _providerEmailController.dispose();
    _conditionTreatedController.dispose();
    super.dispose();
  }

  void _saveProvider() async {
    //check to see if form is validated
    if (_formKey.currentState!.validate()) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('User not logged in');
        return;
      }

      try {
        Map<String, dynamic> providerData = {
          'providerName': _providerNameController.text.trim(),
          'providerSpecialty': _providerSpecialtyController.text.trim(),
          'providerNumber': _providerNumberController.text.trim(),
          'providerEmail': _providerEmailController.text.trim(),
          'conditionTreated': _conditionTreatedController.text.trim(),
        };
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('providers')
            .add(providerData);

        Navigator.pop(context);
      } catch (e) {
        debugPrint('Failed to save provider information: $e');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save provider information: $e')),
        );
      }
    } else {
      debugPrint('Form validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please correct the errors in the form')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFE3E3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Add Healthcare Provider',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        automaticallyImplyLeading: false,
        // Disable default leading icon (hamburger menu)
        actions: [
          //close button icon
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                iconSize: 36,
                //navigate to health data page if user clicks close
                onPressed: () {
                  Navigator.pop(context);
                },
              );
            },
          ),
        ],
      ),

      //body start
      body: Padding(
          padding: const EdgeInsets.all(3.0),
          child: SingleChildScrollView(
              child: Form(
            key: _formKey,
            child: Column(
              children: [
                //provider name and specialty
                SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFFDFFEF),
                              border: Border.all(color: Color(0xFFFF6565)),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10.0),
                              //textfield for provider name
                              child: TextFormField(
                                controller: _providerNameController,
                                textCapitalization: TextCapitalization.words,
                                autocorrect: false,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Provider Name',
                                  hintStyle: TextStyle(fontSize: 18),
                                ),
                                style: TextStyle(
                                    fontSize: 18, color: Color(0xFF545354)),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Provider Name is required';
                                  }
                                  return null;
                                },
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
                              padding: const EdgeInsets.only(left: 10.0),
                              //textfield for provider specialty
                              child: TextFormField(
                                controller: _providerSpecialtyController,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Provider Specialty',
                                  hintStyle: TextStyle(fontSize: 18),
                                ),
                                style: TextStyle(
                                    fontSize: 18, color: Color(0xFF545354)),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Provider Specialty is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                //provider number and email
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFFDFFEF),
                              border: Border.all(color: Color(0xFFFF6565)),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10.0),
                              //textfield for provider number
                              child: TextFormField(
                                controller: _providerNumberController,
                                keyboardType: TextInputType.phone,
                                //only allows digits to be entered
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Number is required';
                                  }
                                  return null;
                                },

                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Provider Number',
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
                              padding: const EdgeInsets.only(left: 10.0),
                              //textfield for provider email
                              child: TextFormField(
                                controller: _providerEmailController,
                                keyboardType: TextInputType.emailAddress,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[a-zA-Z0-9@._-]')),
                                ],
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final emailRegex = RegExp(
                                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                                    if (!emailRegex.hasMatch(value)) {
                                      return 'Enter a valid email';
                                    }
                                  }
                                  return null; // Pass validation if empty or valid
                                },
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Provider Email',
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

                //notes
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFFDFFEF),
                      border: Border.all(color: Color(0xFFFF6565)),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextFormField(
                        controller: _conditionTreatedController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter condition(s) being treated',
                          hintStyle: TextStyle(fontSize: 18),
                        ),
                        style:
                            TextStyle(fontSize: 18, color: Color(0xFF545354)),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                //save button -- lots of these types of buttons repeated so we should make it a widget
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: GestureDetector(
                    //when clicked it should save meds to firestore and schedule notifs
                    //let's hope :/
                    onTap: _saveProvider,
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
                          'Save Provider',
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
                //end of stuff
              ],
            ),
          ))),
      //body end
    );
  }
}
