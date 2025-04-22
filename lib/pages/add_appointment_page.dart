import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AddAppointmentPage extends StatefulWidget {
  const AddAppointmentPage({super.key});

  @override
  State<AddAppointmentPage> createState() => _AddAppointmentPageState();
}

class _AddAppointmentPageState extends State<AddAppointmentPage> {
  //form key to be used for validation
  final _formKey = GlobalKey<FormState>();

  //vars for form fields
  final _notesController = TextEditingController();
  String? _selectedProvider;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  //function to get list of prov names from firestore based on user id
  Future<List<String>> _fetchProviderNames() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('providers')
          .get();
      return snapshot.docs.map((doc) => doc['providerName'] as String).toList();
    } catch (e) {
      debugPrint('Error fetching provider names: $e');
      return [];
    }
  }

  //date picker
  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  //time picker
  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  //function to save appointment to firestore
  void _saveAppointment() async {
    //use formkey to check validity
    if (_formKey.currentState!.validate()) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('User not logged in');
        return;
      }

      //try saving data if appropriate
      try {
        //map appointment data based on user input
        Map<String, dynamic> appointmentData = {
          'providerName': _selectedProvider,
          'appointmentDate': DateFormat('yyyy-MM-dd').format(_selectedDate!),
          'appointmentTime': _selectedTime!.format(context),
          'notes': _notesController.text.trim(),
        };

        //save data map in firestore collection
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('appointments')
            .add(appointmentData);

        //take user back to main appointment page after save
        Navigator.pop(context);
      } catch (e) {
        debugPrint('Failed to save appointment: $e');

        //if saving fails, display error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save appointment: $e')),
        );
      }
    } else {
      debugPrint('Form validation failed');
      //display error messages for missing/invalid input
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please correct the errors in the form')),
      );
    }
  }

  @override
  //dispose of controllers to help with in app memory management
  void dispose() {
    _notesController.dispose();
    super.dispose();
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
          'Add Appointment',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            iconSize: 36,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(3.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  //fetch provider names and display as dropdown list
                  child: FutureBuilder<List<String>>(
                    future: _fetchProviderNames(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        return Text('Error fetching providers');
                      }
                      final providers = snapshot.data ?? [];
                      return Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFFDFFEF),
                          border: Border.all(color: Color(0xFFFF6565)),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        //provider dropdown
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: DropdownButtonFormField<String>(
                            value: _selectedProvider,
                            items: providers
                                .map((provider) => DropdownMenuItem(
                                      value: provider,
                                      child: Text(provider),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedProvider = value;
                              });
                            },
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Select Provider',
                              hintStyle: TextStyle(fontSize: 18),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Provider is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        //date picker
                        child: GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFFDFFEF),
                              border: Border.all(color: Color(0xFFFF6565)),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.all(15.0),
                            child: Text(
                              _selectedDate == null
                                  ? 'Select Date'
                                  : DateFormat('yyyy-MM-dd')
                                      .format(_selectedDate!),
                              style: TextStyle(
                                  fontSize: 18, color: Color(0xFF545354)),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),

                      //time picker
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickTime,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFFDFFEF),
                              border: Border.all(color: Color(0xFFFF6565)),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.all(15.0),
                            child: Text(
                              _selectedTime == null
                                  ? 'Select Time'
                                  : _selectedTime!.format(context),
                              style: TextStyle(
                                  fontSize: 18, color: Color(0xFF545354)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFFDFFEF),
                      border: Border.all(color: Color(0xFFFF6565)),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      //notes text field
                      padding: const EdgeInsets.all(10.0),
                      child: TextFormField(
                        controller: _notesController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter notes',
                          hintStyle: TextStyle(fontSize: 18),
                        ),
                        style:
                            TextStyle(fontSize: 18, color: Color(0xFF545354)),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  //save appointment button
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: GestureDetector(
                    onTap: _saveAppointment,
                    child: Container(
                      padding: EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFF6565),
                            Color(0xFFFF5050),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Center(
                        child: Text(
                          'Save Appointment',
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
