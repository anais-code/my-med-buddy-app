import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_med_buddy_app/widgets/section_divider.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:my_med_buddy_app/Services/notifications.dart';
import 'package:intl/intl.dart';

class AddMedPage extends StatefulWidget {
  final Map<String, dynamic>? medicationData; // Added this parameter
  final String? medicationId; // Added this parameter

  const AddMedPage({super.key, this.medicationData, this.medicationId});

  @override
  State<AddMedPage> createState() => _AddMedPageState();
}

class _AddMedPageState extends State<AddMedPage> {
  //initialise controllers for text input from user
  final _searchBarController = TextEditingController();
  final _medicationNameController = TextEditingController();
  final _currentInventoryController = TextEditingController();
  final _inventoryThresholdController = TextEditingController();
  final _notesController = TextEditingController();

  //vars to collect user input
  String? medUnits;

  //declare values for units
  final List<String> unitsOptions = [
    'Pill(s)',
    'Capsule(s)',
    'Tablespoon(s)',
    'Teaspoon(s)',
    'Millimeter(s)',
    'Injection(s)',
    'Vial(s)',
    'Drop(s)',
    'Puff(s)',
    'Unit(s)'
  ];

  //declare values for frequency
  final Map<int, String> frequencyOptions = {
    1: 'Once Daily',
    2: 'Twice Daily',
    3: 'Three Times Daily',
    4: 'Four Times Daily',
    5: 'Five Times Daily',
    6: 'Six Times Daily',
    7: 'Seven Times Daily',
    8: 'Eight Times Daily',
    9: 'Nine Times Daily',
    10: 'Ten Times Daily',
  };

  //initalise to once daily
  int medFrequency = 1;
  //stores selected times and dosages
  List<TimeOfDay?> medTimes = [null];
  List<int> medDosages = [1];

  //initialise bools to enable reminders
  bool _isMedReminderEnabled = false;
  bool _isThresholdReminderEnabled = false;

  //helper method to change convert time strings into objects
  TimeOfDay? _parseTimeString(String timeString) {
    try {
      final timeFormat = DateFormat.jm(); // Use the 'jm' format for parsing "2:35 PM"
      final dateTime = timeFormat.parse(timeString);
      return TimeOfDay.fromDateTime(dateTime);
    } catch (e) {
      debugPrint('Failed to parse time string: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();

    // Pre-fill the form fields if medicationData is provided
    if (widget.medicationData != null) {
      _medicationNameController.text = widget.medicationData!['medicationName'];
      _currentInventoryController.text = widget.medicationData!['currentInventory'].toString();
      _inventoryThresholdController.text = widget.medicationData!['inventoryThreshold'].toString();
      medUnits = widget.medicationData!['medUnits'];
      medFrequency = widget.medicationData!['medFrequency'];
      _isMedReminderEnabled = widget.medicationData!['isMedReminderEnabled'];
      _isThresholdReminderEnabled = widget.medicationData!['isThresholdReminderEnabled'];
      _notesController.text = widget.medicationData!['notes'];

      // Pre-fill medTimes and medDosages if available
      if (widget.medicationData!['medTimes'] != null) {
        medTimes = (widget.medicationData!['medTimes'] as List)
            .map((time) => time != null ? _parseTimeString(time) : null)
            .toList();
      }
      if (widget.medicationData!['medDosages'] != null) {
        medDosages = List<int>.from(widget.medicationData!['medDosages']);
      }
    }
  }

  Future<void> _requestNotificationPermissions() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
    if (!status.isGranted) {
      debugPrint('Notification permissions not granted');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification permissions are required for reminders.')),
      );
    }
  }

  @override
  //dispose of controllers to help with in app memory management
  void dispose() {
    _searchBarController.dispose();
    _medicationNameController.dispose();
    _currentInventoryController.dispose();
    _inventoryThresholdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  //dynamically update the time and dosage section based on med frequency
  void _updateTimeandDosageFields() {
    setState(() {
      medTimes = List.filled(medFrequency, null);
      medDosages = List.filled(medFrequency, 1);
    });
  }

  //method to save medication to firestore collection, linked to uid
  //NEEDS TRY CATCH IMPLEMENTATION
  void _saveMedication() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in');
      return;
    }

    // Validate medFrequency and medTimes
    if (medFrequency != medTimes.length) {
      debugPrint('medFrequency and medTimes length mismatch');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all medication times.')),
      );
      return;
    }


    try {
      // Save medication data to Firestore
      Map<String, dynamic> medData = {
        'medicationName': _medicationNameController.text,
        'medUnits': medUnits,
        'medFrequency': medFrequency,
        'medTimes': medTimes.map((time) => time?.format(context)).toList(),
        'medDosages': medDosages,
        'isMedReminderEnabled': _isMedReminderEnabled,
        'currentInventory': int.tryParse(_currentInventoryController.text) ?? 0,
        'inventoryThreshold': int.tryParse(_inventoryThresholdController.text) ?? 0,
        'isThresholdReminderEnabled': _isThresholdReminderEnabled,
        'notes': _notesController.text,
      };
    if (widget.medicationId == null) {
      // Add new medication
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medications')
          .add(medData);
    }else {
    // Update existing medication
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medications')
          .doc(widget.medicationId)
          .update(medData);
    }

      // Cancel existing notifications if reminders are disabled
      if (!_isMedReminderEnabled) {
        for (int i = 0; i < medFrequency; i++) {
          try {
            await Notifications().cancelNotifications(i);
          } catch (e) {
            debugPrint('Failed to cancel notification: $e');
          }
        }
      }

      // Schedule notifications if enabled
      if (_isMedReminderEnabled) {
        await _requestNotificationPermissions(); // Request permissions

        if (await Permission.notification.status.isGranted) {
          for (int i = 0; i < medFrequency; i++) {
            if (medTimes[i] != null) {
              TimeOfDay time = medTimes[i]!;
              try {
                await Notifications().scheduleNotification(
                  id: i,
                  title: 'Medication Reminder',
                  body:
                  'Take ${_medicationNameController.text}: ${medDosages[i]
                      .toString()} ${medUnits ?? ''}',
                  hour: time.hour,
                  minute: time.minute,
                );
              } catch (e) {
                debugPrint('Failed to schedule notification: $e');
              }
            }
          }
        }
      }

      // Check if the widget is still mounted before using context
      if (!mounted) return;
      // Navigate back on success
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Failed to save medication: $e');

      // Check if the widget is still mounted before using context
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save medication: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFFEF),
      // Light background color
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          widget.medicationData == null ? 'Add Medication': 'Edit Medication', //Update title
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
                //navigate to med page if user clicks close
                onPressed: () {
                  Navigator.pop(context);
                },
              );
            },
          ),
        ],
      ),

      //Body
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              //search bar controller -- NOT YET IMPLEMENTED needs OpenFDA API
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFFDFFEF),
                    border: Border.all(color: Color(0xFFFF6565)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  //textfield for searching
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: TextField(
                      controller: _searchBarController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search, color: Colors.black),
                        hintText: 'Search for a name',
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

              //manual medication name controller -- this is all that will be used for now
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFFDFFEF),
                    border: Border.all(color: Color(0xFFFF6565)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  //textfield for medication name
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: TextField(
                      controller: _medicationNameController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter Medication Name',
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
              SectionDivider(),
              SizedBox(height: 20),

              //row for units and frequency
              //unit picker
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
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
                                hint: Text("Unit",
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.grey)),
                                value: medUnits,
                                isExpanded: true,
                                items: unitsOptions.map((String units) {
                                  return DropdownMenuItem<String>(
                                    value: units,
                                    child: Text(units,
                                        style: TextStyle(
                                            fontSize: 18,
                                            color: Color(0xFF545354))),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    medUnits = newValue;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    //frequency picker
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
                              child: DropdownButton<int>(
                                hint: Text("Daily Frequency",
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.grey)),
                                value: medFrequency,
                                isExpanded: true,
                                items: frequencyOptions.entries.map((entry) {
                                  return DropdownMenuItem<int>(
                                    value: entry.key,
                                    child: Text(entry.value,
                                        style: TextStyle(
                                            fontSize: 18,
                                            color: Color(0xFF545354))),
                                  );
                                }).toList(),
                                onChanged: (int? newValue) {
                                  if (newValue != null) {
                                    //create time/dosage slots based on chosen frequency
                                    setState(() {
                                      medFrequency = newValue;
                                      _updateTimeandDosageFields();
                                    });
                                  }
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
              SectionDivider(),
              SizedBox(height: 20),

              //dynamically generated rows for time and dosage
              Container(
                //simple styling to ensure that slots do not overflow or leave blank space
                height: medFrequency * 70.0,
                child: ListView.builder(
                  shrinkWrap: true, //to prevent scroll conflicts
                  physics: NeverScrollableScrollPhysics(),
                  //rows are based off of number chosen for frequency
                  itemCount: medFrequency,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 1.5, horizontal: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          //time picker
                          //very cute because it looks like a textfield but it's a hidden button
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                TimeOfDay? pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (pickedTime != null) {
                                  setState(() {
                                    medTimes[index] = pickedTime;
                                  });
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 16.0),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFDFFEF),
                                  border: Border.all(color: Color(0xFFFF6565)),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  medTimes[index]?.format(context) ??
                                      'Choose Time',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: medTimes[index] != null
                                        ? Color(0xFF545354)
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 10),

                          //dosage picker
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xFFFDFFEF),
                                border: Border.all(color: Color(0xFFFF6565)),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 10.0),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  hint: Text("Dosage",
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.grey)),
                                  value: medDosages[index],
                                  isExpanded: true,
                                  //generates # of dosages 1-10
                                  items: List.generate(10, (i) => i + 1)
                                      .map((value) {
                                    return DropdownMenuItem<int>(
                                      value: value,
                                      child: Text(
                                        '$value',
                                        style: TextStyle(
                                            fontSize: 18,
                                            color: Color(0xFF545354)),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (int? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        medDosages[index] = newValue;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              SectionDivider(),
              SizedBox(height: 20),

              //enable med reminders toggle
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.0),
                child: SwitchListTile(
                  title: Text('Enable Medication Reminders?',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF545354),
                      )),
                  value: _isMedReminderEnabled,
                  onChanged: (bool value) {
                    //set to true or false based on toggle state
                    //influences notifs
                    setState(() {
                      _isMedReminderEnabled = value;
                    });
                  },
                  activeColor: Colors.green,
                  subtitle: Text(
                    _isMedReminderEnabled
                        ? "You will receive notifications for this medication."
                        : "No reminders will be sent.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),

              SizedBox(height: 20),
              SectionDivider(),
              SizedBox(height: 20),

              //current inventory
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
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
                            //textfield for current inventory
                            //ensure that only digits can be entered
                            child: TextField(
                              controller: _currentInventoryController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Enter Current Units',
                                hintStyle: TextStyle(fontSize: 14),
                              ),
                              style: TextStyle(
                                  fontSize: 14, color: Color(0xFF545354)),
                            ),
                          ),
                        ),
                      ),
                    ),

                    //inventory threshold
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
                            //textfield for inventory threshold
                            //again digits only
                            child: TextField(
                              controller: _inventoryThresholdController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Enter Unit Threshold',
                                hintStyle: TextStyle(fontSize: 14),
                              ),
                              style: TextStyle(
                                  fontSize: 14, color: Color(0xFF545354)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),
              //enable reminders toggle
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.0),
                child: SwitchListTile(
                  title: Text('Enable Medication Threshold Reminders?',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF545354),
                      )),
                  value: _isThresholdReminderEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _isThresholdReminderEnabled = value;
                    });
                  },
                  activeColor: Colors.green,
                  subtitle: Text(
                    _isThresholdReminderEnabled
                        ? "You will receive notifications when threshold is reached."
                        : "No reminders will be sent.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),

              SizedBox(height: 20),
              SectionDivider(),
              SizedBox(height: 20),

              //notes
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
                      controller: _notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Notes',
                        hintStyle: TextStyle(fontSize: 18),
                      ),
                      style: TextStyle(fontSize: 18, color: Color(0xFF545354)),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              SizedBox(height: 20),

              //save button -- lots of these types of buttons repeated so we should make it a widget
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: GestureDetector(
                  //when clicked it should save meds to firestore and schedule notifs
                  //let's hope :/
                  onTap: _saveMedication,
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
                        'Save Medication',
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

              //end -- that was a lot -- needs clean up
            ],
          ),
        ),
      ),
    );
  }
}
