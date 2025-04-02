import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_med_buddy_app/Services/authentication.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Services/notifications.dart';
import 'milestone_page.dart';
import 'signup_login.dart';
import 'medication_page.dart';
import 'health_data_page.dart';
import '../Services/app_utils.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});
  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _userData;
  bool _isLoading = true; // Track loading state

  // Declare obj of auth services class
  final AuthServices _authService = AuthServices();

  // Helper method to clean time strings
  String _cleanTimeString(String timeString) {
    // Remove any non-standard or invisible characters
    return timeString.replaceAll(RegExp(r'[^0-9:APMapm\s]'), '').trim();
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    //_updateStreak();
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          setState(() {
            _userData = userDoc.data() as Map<String, dynamic>?;
            _isLoading = false; // Data fetched, stop loading
          });
        } else {
          debugPrint('User document does not exist in Firestore');
          setState(() {
            _isLoading = false; // Stop loading even if no data
          });
        }
      } else {
        debugPrint('No user is currently signed in');
        setState(() {
          _isLoading = false; // Stop loading if no user
        });
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      setState(() {
        _isLoading = false; // Stop loading on error
      });
    }
  }

  // Fetch medications stream
  Stream<QuerySnapshot> _getMedicationsStream() {
    final User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('medications')
        .snapshots();
  }

  // Check if a medication has been taken today
  Future<bool> _isMedicationTakenToday(String medicationId) async {
    final User? user = _auth.currentUser;
    if (user == null) return false;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final logsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('medicationLogs')
        .where('medicationId', isEqualTo: medicationId)
        .where('userId', isEqualTo: user.uid)
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThan: endOfDay)
        .get();

    return logsSnapshot.docs.isNotEmpty;
  }

  // Log medication taken
  Future<void> _logMedicationTaken(String medicationId, medicationName) async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
      // Fetch the medication document
      final medDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medications')
          .doc(medicationId)
          .get();

      if (!medDoc.exists) {
        debugPrint('Medication document does not exist');
        return;
      }

      final medData = medDoc.data() as Map<String, dynamic>;
      final currentInventory = medData['currentInventory'] as int;
      final inventoryThreshold = medData['inventoryThreshold'] as int;

      // Check if current inventory is above the threshold
      if (currentInventory > 0) {
        // Decrement the current inventory
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('medications')
            .doc(medicationId)
            .update({
          'currentInventory': FieldValue.increment(-1),
        });

        await _firestore
            .collection('users') // Access the users collection
            .doc(user.uid) // Access the specific user's document
            .collection(
                'medicationLogs') // Access the medicationLogs subcollection
            .add({
          'medicationId': medicationId,
          'medicationName': medicationName,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Update the streak counter
        await _updateStreak();
        // Refresh the UI to reflect the change
        setState(() {});

        // Show a motivational popup
        if (!mounted) return;
        AppUtils.showMotivationalPopup(
            context); // Use the function from app_utils.dart

        // Check if inventory has reached the threshold
        if (currentInventory - 1 <= inventoryThreshold) {
          // Trigger a notification or alert for low inventory
          debugPrint('Inventory threshold reached for $medicationName');

          //Trigger a notification for low inventory
          await Notifications().scheduleNotification(
            id: DateTime.now().millisecondsSinceEpoch % 100000, // Unique ID
            title: 'Low Inventory Alert',
            body: 'Your inventory for $medicationName is running low!',
            hour: DateTime.now().hour,
            minute: DateTime.now().minute + 1, // Schedule for 1 minute later
          );
        }
      } else {
        debugPrint('Inventory is already at or below the threshold');
      }
    } catch (e) {
      debugPrint('Failed to log medication: $e');
    }
  }

  // Function to update the streak counter
  Future<void> _updateStreak() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Check if the user has logged any medication today
    final logsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('medicationLogs')
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThan: endOfDay)
        .get();

    if (logsSnapshot.docs.isNotEmpty) {
      // User has logged medication today, increment streak
      await _firestore.collection('users').doc(user.uid).update({
        'streak': FieldValue.increment(1),
      });
    } else {
      // User has not logged medication today, reset streak
      await _firestore.collection('users').doc(user.uid).update({
        'streak': 0,
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMedicationData(
      List<QueryDocumentSnapshot> medications) async {
    final List<Map<String, dynamic>> medicationData = [];

    for (final med in medications) {
      final data = med.data() as Map<String, dynamic>;
      final medicationId = med.id; // Access the document ID
      debugPrint(
          'Processing medication: ${data['medicationName']}, ID: $medicationId');

      // Check if the medication has been taken today
      final isTaken = await _isMedicationTakenToday(medicationId);
      debugPrint('isTaken: $isTaken');

      // Get the list of times for the medication, ensure correct type
      final medTimes = List<dynamic>.from(data['medTimes'] ?? []);
      debugPrint('medTimes: $medTimes');

      // Get the current date and time
      final now = DateTime.now();

      // Parse each time string into a DateTime object
      final parsedTimes = medTimes
          .map((timeString) {
            if (timeString is String) {
              try {
                final cleanedTimeString = _cleanTimeString(timeString);
                debugPrint(
                    'Original: $timeString, Cleaned: $cleanedTimeString');
                final medTime = DateFormat('h:mm a').parse(cleanedTimeString);
                debugPrint('Parsed: $medTime');
                return DateTime(
                    now.year, now.month, now.day, medTime.hour, medTime.minute);
              } catch (e) {
                debugPrint(
                    'Failed to parse time string: $timeString, Error: $e');
                return null;
              }
            } else {
              debugPrint('Invalid time string: $timeString');
              return null;
            }
          })
          .whereType<DateTime>()
          .toList();

      debugPrint('parsedTimes: $parsedTimes');

      // Add the processed data to the list
      medicationData.add({
        ...data, // Include all existing data
        'medicationId': medicationId, // Add the medication ID
        'parsedTimes': parsedTimes, // Add the parsed times
        'isTaken':
            isTaken, // Add a flag to indicate if the medication has been taken
      });
    }

    debugPrint('Processed medications: ${medicationData.length}');
    return medicationData;
  }

  // Streak counter widget
  Widget _buildStreakCounter() {
    final User? user = _auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('No streak data found');
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final streak = userData['streak'] ?? 0;

        return Row(
          children: [
            Image.asset(
              'assets/images/mmb_streak_icon.png',
              height: 70,
              width: 60,
            ),
            const SizedBox(width: 8),
            Text(
              "$streak", // Dynamic streak count
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        );
      },
    );
  }

  // Method to use sign out from authentication.dart
  void _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    // Navigates back to signup_login screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => SignupLoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE3E3), // Light background color
      appBar: AppBar(
        title: _buildStreakCounter(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading:
            false, // Disable default leading icon (hamburger menu)
        actions: [
          // Hamburger Menu Icon
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                iconSize: 36,
                onPressed: () {
                  // Open the drawer from the right
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),

      // Sidebar (Drawer)
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer Header with User Info
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFFFF6565), // Red color
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  else if (_userData != null) ...[
                    Text(
                      '${_userData!['firstName']} ${_userData!['lastName']}',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Age: ${_userData!['age'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Conditions: ${_userData!['conditions'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ] else
                    const Text(
                      'No user data found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),

            // Drawer Items
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                // Navigate to Home Page
                Navigator.pop(context); // Close the drawer
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigating to Home Page')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Calendar'),
              onTap: () {
                // Navigate to Calendar Page
                Navigator.pop(context); // Close the drawer
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigating to Calendar Page')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () {
                // Navigate to Notifications Page
                Navigator.pop(context); // Close the drawer
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Navigating to Notifications Page')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                // Navigate to Settings Page
                Navigator.pop(context); // Close the drawer
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigating to Settings Page')),
                );
              },
            ),
            // Logout Button
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _signOut,
            ),
          ],
        ),
      ),

      // Body
      body: Column(
        children: [
          // Centered title
          Container(
            height: 100, // Adjust height as needed
            alignment: Alignment.center, // Center the text
            child: const Text(
              "Today's Schedule",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),

          // Scrollable list of schedule items using StreamBuilder
          Expanded(
              child: StreamBuilder<QuerySnapshot>(
            stream: _getMedicationsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                debugPrint('Waiting for data...');
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                debugPrint('No medications found in Firestore');
                return const Center(child: Text('No medications found'));
              }

              final medications = snapshot.data!.docs;
              debugPrint(
                  'Fetched ${medications.length} medications from Firestore');

              // Use a FutureBuilder to fetch and process medication data asynchronously
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchMedicationData(medications),
                builder: (context, futureSnapshot) {
                  if (futureSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    debugPrint('Processing medication data...');
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!futureSnapshot.hasData || futureSnapshot.data!.isEmpty) {
                    debugPrint('No medications to display after processing');
                    return const Center(
                        child: Text('No medications to display'));
                  }

                  final medicationData = futureSnapshot.data!;
                  debugPrint('Processed ${medicationData.length} medications');

                  // Build the ListView to display the medications
                  return ListView.builder(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                    itemCount: medicationData.length,
                    itemBuilder: (context, index) {
                      final data = medicationData[index];
                      debugPrint(
                          'Displaying medication: ${data['medicationName']}');

                      // Only display medications that have not been taken today
                      if (data['isTaken']) {
                        return const SizedBox
                            .shrink(); // Hide the medication if it has been taken
                      }
                      // Build a Column for each medication
                      return Column(
                        children: [
                          for (final medTime in data['parsedTimes'])
                            // Build a schedule item for each time
                            _buildScheduleItem(
                              time: DateFormat.jm()
                                  .format(medTime), // Format the time
                              title: data['medicationName'], // Medication name
                              subtitle:
                                  '${(data['medDosages'] as List<dynamic>).join()} ${data['medUnits']}', // Dosage and units
                              onCheck: () => _logMedicationTaken(
                                  data['medicationId'],
                                  data['medicationName']), // Log medication
                              isTaken: data['isTaken'], // Pass the isTaken flag
                            ),
                          // Add spacing between medications
                          const SizedBox(height: 30),
                        ],
                      );
                    },
                  );
                },
              );
            },
          )),
        ],
      ),

      // Bottom Snack Bar with Four Elements
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFFFF6565), // Red color
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Schedule page icon
              IconButton(
                icon: Image.asset(
                  'assets/images/mmb_schedule_icon.png',
                  height: 38,
                  width: 38,
                ),
                onPressed: () {
                  // Navigate to Schedule page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SchedulePage()),
                  );
                },
              ),

              // Medication page icon
              IconButton(
                icon: Image.asset(
                  'assets/images/mmb_medication_icon.png',
                  height: 38,
                  width: 38,
                ),
                onPressed: () {
                  // Navigate to medication page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MedicationPage()),
                  );
                },
              ),

              // Health data icon
              IconButton(
                icon: Image.asset(
                  'assets/images/mmb_health_icon.png',
                  height: 38,
                  width: 38,
                ),
                onPressed: () {
                  // Navigate to health data page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HealthDataPage()),
                  );
                },
              ),

              // Progress/milestone icon
              IconButton(
                icon: Image.asset(
                  'assets/images/mmb_progress_icon.png',
                  height: 38,
                  width: 38,
                ),
                onPressed: () {
                  // Navigate to milestone page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MilestonePage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build a schedule item
  Widget _buildScheduleItem({
    required String time,
    required String title,
    required String subtitle,
    required VoidCallback onCheck,
    required bool isTaken,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Time
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE3E3), // Light pink background
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF5050), // Red text color
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Title and Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Log Medication Button or Checkmark
          if (isTaken)
            const Icon(Icons.check_circle,
                color: Colors.green) // Show checkmark if taken
          else
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: onCheck, // Allow logging if not taken
            ),
        ],
      ),
    );
  }
}
