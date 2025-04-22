import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_med_buddy_app/widgets/section_divider.dart';
import 'package:flutter/services.dart';
import 'package:my_med_buddy_app/Services/notifications.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_typeahead/flutter_typeahead.dart';

class AddMedPage extends StatefulWidget {
  final Map<String, dynamic>? medicationData; // Added this parameter
  final String? medicationId; // Added this parameter

  const AddMedPage({super.key, this.medicationData, this.medicationId});

  @override
  State<AddMedPage> createState() => _AddMedPageState();
}

class _AddMedPageState extends State<AddMedPage> {
  //initialise controllers for text input from user
  //final _searchBarController = TextEditingController();
  TextEditingController? _searchBarController;
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
      final timeFormat =
          DateFormat.jm(); // Use the 'jm' format for parsing "2:35 PM"
      final dateTime = timeFormat.parse(timeString);
      return TimeOfDay.fromDateTime(dateTime);
    } catch (e) {
      debugPrint('Failed to parse time string: $e');
      return null;
    }
  }

  //function to fetch medication names using OpenFDA API
  Future<List<String>> _fetchMedNames(String query) async {
    debugPrint('Fetching medications for query: $query');
    if (query.isEmpty) {
      debugPrint('Query is empty. Returning no suggestions.');
      return [];
    }

    //encode url to handle special chars
    final encodedQuery = Uri.encodeComponent(query.trim().toLowerCase());

    //api url definition to search for brand names
    final url =
        'https://api.fda.gov/drug/label.json?search=openfda.brand_name:$encodedQuery&limit=50';

    try {
      final response = await http.get(Uri.parse(url));

      //if respinse is sucessful, parse json data and put into list
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];

        //get brand names from results and convert to string list
        List<String> suggestions = results
            .map((item) {
              final brandNames =
                  item['openfda']?['brand_name'] as List<dynamic>?;
              return (brandNames != null && brandNames.isNotEmpty)
                  ? brandNames.first as String
                  : '';
            })
            .where((name) => name.isNotEmpty)
            .toList();

        //filter suggestions based on start of query
        suggestions = suggestions.where((name) {
          return name.toLowerCase().startsWith(query.toLowerCase());
        }).toList();

        return suggestions;
      } else {
        debugPrint('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }

    return [];
  }

  @override
  void initState() {
    super.initState();

    //prefill the form if the user has an exisitng medication -- used for dynamic form editing
    if (widget.medicationData != null) {
      _medicationNameController.text = widget.medicationData!['medicationName'];
      _currentInventoryController.text =
          widget.medicationData!['currentInventory'].toString();
      _inventoryThresholdController.text =
          widget.medicationData!['inventoryThreshold'].toString();
      medUnits = widget.medicationData!['medUnits'];
      medFrequency = widget.medicationData!['medFrequency'];
      _isMedReminderEnabled = widget.medicationData!['isMedReminderEnabled'];
      _isThresholdReminderEnabled =
          widget.medicationData!['isThresholdReminderEnabled'];
      _notesController.text = widget.medicationData!['notes'];

      //prefill med time and dosage
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

  @override
  //dispose of controllers to help with in app memory management
  void dispose() {
    //_searchBarController.dispose();
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
  void _saveMedication() async {
    //ensure medication name, units and times are filled out
    if (_medicationNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a medication name.')),
      );
      return;
    }

    if (medUnits == null || medUnits!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a unit for your medication.')),
      );
      return;
    }
    if (medTimes.any((time) => time == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a time for each dose.')),
      );
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('User not logged in');
      return;
    }

    //validate frequency and times
    if (medFrequency != medTimes.length) {
      debugPrint('medFrequency and medTimes length mismatch');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all medication times.')),
      );
      return;
    }

    try {
      //save med to firestore
      Map<String, dynamic> medData = {
        'medicationName': _medicationNameController.text,
        'medUnits': medUnits,
        'medFrequency': medFrequency,
        'medTimes': medTimes.map((time) => time?.format(context)).toList(),
        'medDosages': medDosages,
        'isMedReminderEnabled': _isMedReminderEnabled,
        'currentInventory': int.tryParse(_currentInventoryController.text) ?? 0,
        'inventoryThreshold':
            int.tryParse(_inventoryThresholdController.text) ?? 0,
        'isThresholdReminderEnabled': _isThresholdReminderEnabled,
        'notes': _notesController.text,
      };
      //if no med ID exisits, add data as new medication in firestore
      if (widget.medicationId == null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('medications')
            .add(medData);
      } else {
        //update data if med exists
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('medications')
            .doc(widget.medicationId)
            .update(medData);
      }

      //cancel notifs if reminders are disables
      if (!_isMedReminderEnabled) {
        for (int i = 0; i < medFrequency; i++) {
          try {
            await Notifications().cancelNotifications(i);
          } catch (e) {
            debugPrint('Failed to cancel notification: $e');
          }
        }
      }

      //schedyle notif is reminders are enabled
      if (_isMedReminderEnabled) {
        for (int i = 0; i < medFrequency; i++) {
          if (medTimes[i] != null) {
            TimeOfDay time = medTimes[i]!;
            //call method from notif service class to schedule notif
            await Notifications().scheduleNotification(
              //display med name, dosage and units
              id: i,
              title: 'Medication Reminder',
              body:
                  'Take ${_medicationNameController.text}: ${medDosages[i].toString()} ${medUnits ?? ''}',
              hour: time.hour,
              minute: time.minute,
            );
          }
        }
      }

      if (!mounted) return;
      //return to medications page if succcessful
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Failed to save medication: $e');

      if (!mounted) return;
      //show error if saving fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save medication: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFFEF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          widget.medicationData == null ? 'Add Medication' : 'Edit Medication',
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
              //search bar controller
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFFDFFEF),
                    border: Border.all(color: Color(0xFFFF6565)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0),

                    //allows for suggestions to be shown
                    child: TypeAheadField<String>(
                      builder: (context, controller, focusNode) {
                        _searchBarController = controller;
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search, color: Colors.black),
                            hintText: 'Search for a name',
                            hintStyle: TextStyle(fontSize: 18),
                          ),
                          style:
                              TextStyle(fontSize: 18, color: Color(0xFF545354)),
                        );
                      },
                      suggestionsCallback: (pattern) async {
                        debugPrint(
                            'Suggestions callback triggered with pattern: $pattern');
                        if (pattern.isEmpty) {
                          debugPrint(
                              'Pattern is empty. Returning no suggestions.');
                          return [];
                        }
                        final suggestions = await _fetchMedNames(pattern);
                        debugPrint('Suggestions returned: $suggestions');
                        return suggestions;
                      },
                      itemBuilder: (context, String suggestion) {
                        return ListTile(
                          title: Text(suggestion),
                        );
                      },
                      //place selected text in med name textfield
                      //this is saved to firestore
                      onSelected: (String suggestion) {
                        debugPrint('Suggestion selected: $suggestion');
                        _medicationNameController.text = suggestion;
                        _searchBarController?.clear();
                      },
                      emptyBuilder: (context) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'No medications found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),

              //manual medication name controller
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
