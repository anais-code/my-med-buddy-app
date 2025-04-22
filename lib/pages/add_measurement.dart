import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_med_buddy_app/Services/blood_pressure_formatter.dart';
import 'package:intl/intl.dart';

class AddMeasurementPage extends StatefulWidget {
  const AddMeasurementPage({super.key});
  @override
  State<AddMeasurementPage> createState() => _AddMeasurementPageState();
}

class _AddMeasurementPageState extends State<AddMeasurementPage> {
  //form key for validation
  final _formKey = GlobalKey<FormState>();
  //vars for user input
  String? _selectedMeasurementType;
  final TextEditingController _heartRateController = TextEditingController();
  final TextEditingController _bloodPressureController = TextEditingController();
  final TextEditingController _bloodOxygenController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  //list of measurement options
  final List<String> _measurementTypes = [
    'Heart Rate',
    'Blood Pressure',
    'Blood Oxygen',
    'Weight',
    'Height'
  ];

  @override
  //disposes of controllers to help with in-app memory managment
  void dispose() {
    _heartRateController.dispose();
    _bloodPressureController.dispose();
    _bloodOxygenController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _saveMeasurement() async {

    //check to see if form is validated
    if (_formKey.currentState!.validate()) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('User not logged in');
        return;
      }

      //check for measurement type input
      if (_selectedMeasurementType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a measurement type')),
        );
        return;
      }

      String measurement = '';

      //match selections to textfield values
      switch (_selectedMeasurementType) {
        case 'Heart Rate':
          measurement = '${_heartRateController.text.trim()} bpm';
          break;
        case 'Blood Pressure':
          measurement = '${_bloodPressureController.text.trim()} mmHg';
          break;
        case 'Blood Oxygen':
          measurement = '${_bloodOxygenController.text} %';
          break;
        case 'Weight':
          measurement = '${_weightController.text} lbs';
          break;
        case 'Height':
          measurement = '${_heightController.text} cm';
          break;
    }

      //try saving measurement data to firestore
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('measurements')
            .add({
              'measurementType': _selectedMeasurementType,
              'value': measurement,
              'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
            });
        //navigate back to healt data page
        Navigator.pop(context);
      } catch (e) {
        debugPrint('Failed to save measurement: $e');

        //display error for measurement saving failure
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save measurement: $e')),
        );
      }
    } else {
      //display error for invalid or missing user input
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

      //app bar with title and close button
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Add Measurement',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //measurement type dropdown box
                Padding(
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
                          hint: Text(
                            "Select Measurement",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          value: _selectedMeasurementType,
                          isExpanded: true,
                          items: _measurementTypes.map((String measurement) {
                            return DropdownMenuItem<String>(
                              value: measurement,
                              child: Text(
                                measurement,
                                style: TextStyle(
                                    fontSize: 18, color: Color(0xFF545354)),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedMeasurementType = newValue;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16),
                //heart rate textfield (if selected)
                if (_selectedMeasurementType == 'Heart Rate') ...[
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
                        //textfield for heart rate
                        child: TextFormField(
                          controller: _heartRateController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter a heart rate';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter heart rate (bpm)',
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
                ]
                //blood pressure textfield (if selected)
                else if (_selectedMeasurementType == 'Blood Pressure') ...[
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
                        //textfield for blood pressure
                        child: TextFormField(
                          controller: _bloodPressureController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [BloodPressureInputFormatter()],
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter blood pressure';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter blood pressure (e.g. 120/80)',
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
                ]
                //blood oxygen textfield (if selected)
                else if (_selectedMeasurementType == 'Blood Oxygen') ...[
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
                        //textfield for blood oxygen level
                        child: TextFormField(
                          controller: _bloodOxygenController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter blood oxygen level';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter blood oxygen level (%)',
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
                ]
                //weight
                else if (_selectedMeasurementType == 'Weight') ...[
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
                        //textfield for weight
                        child: TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter weight';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter weight (lbs)',
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
                ]
                //height
                else if (_selectedMeasurementType == 'Height') ...[
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
                        //textfield for weight
                        child: TextFormField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter height';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter height (cm)',
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
                ],
                //space between save button
                SizedBox(height: 25),

                //save button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: GestureDetector(
                    //when clicked, saves measurements to firestore
                    onTap: _saveMeasurement,
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
                          'Save Measurement',
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

      //body end
    );
  }
}
