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

  @override
  void initState() {
    super.initState();
    _fetchUserData();
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
        .collection('medicationLogs')
        .where('medicationId', isEqualTo: medicationId)
        .where('userId', isEqualTo: user.uid)
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThan: endOfDay)
        .get();

    return logsSnapshot.docs.isNotEmpty;
  }

  // Log medication taken
  Future<void> _logMedicationTaken(String medicationId) async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('medicationLogs').add({
      'medicationId': medicationId,
      'userId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> _fetchMedicationData(List<QueryDocumentSnapshot> medications) async {
    // List to store processed medication data
    final List<Map<String, dynamic>> medicationData = [];

    // Loop through each medication
    for (final med in medications) {
      // Get the data for the current medication
      final data = med.data() as Map<String, dynamic>;

      // Check if the medication has been taken today
      final isTaken = await _isMedicationTakenToday(med.id);

      // If the medication hasn't been taken today, process it
      if (!isTaken) {
        // Get the list of times for the medication
        final medTimes = data['medTimes'] as List<dynamic>;

        // Get the current date and time
        final now = DateTime.now();

        // Parse each time string into a DateTime object
        final parsedTimes = medTimes.map((timeString) {
          final medTime = DateFormat('h:mm a').parse(timeString as String);
          return DateTime(
            now.year,
            now.month,
            now.day,
            medTime.hour,
            medTime.minute,
          );
        }).toList();

        // Add the processed data to the list
        medicationData.add({
          ...data, // Include all existing data
          'medicationId': med.id, // Add the medication ID
          'parsedTimes': parsedTimes, // Add the parsed times
        });
      }
    }

    // Return the processed medication data
    return medicationData;
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
        title: Row(
          children: [
            // Streak Counter with Flame Icon
            Image.asset(
              'assets/images/mmb_streak_icon.png',
              height: 70,
              width: 60,
            ),
            const SizedBox(width: 8),
            const Text(
              "3", // (TEMPORARY) Replace with dynamic streak count
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false, // Disable default leading icon (hamburger menu)
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
                  const SnackBar(content: Text('Navigating to Notifications Page')),
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
              // Stream to fetch medications from Firestore
              stream: _getMedicationsStream(),
              builder: (context, snapshot) {
                // Show a loading indicator while waiting for data
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Show a message if no medications are found
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No medications found'));
                }

                // Get the list of medications from the snapshot
                final medications = snapshot.data!.docs;

                // Use a FutureBuilder to fetch and process medication data asynchronously
                return FutureBuilder<List<Map<String, dynamic>>>(
                  // Fetch and process medication data
                  future: _fetchMedicationData(medications),
                  builder: (context, futureSnapshot) {
                    // Show a loading indicator while waiting for data
                    if (futureSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    // Show a message if no medications are available to display
                    if (!futureSnapshot.hasData || futureSnapshot.data!.isEmpty) {
                      return const Center(child: Text('No medications to display'));
                    }

                    // Get the processed medication data
                    final medicationData = futureSnapshot.data!;

                    // Build the ListView to display the medications
                    return ListView.builder(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                      itemCount: medicationData.length,
                      itemBuilder: (context, index) {
                        // Get the data for the current medication
                        final data = medicationData[index];

                        // Build a Column for each medication
                        return Column(
                          children: [
                            // Loop through each time for the medication
                            for (final medTime in data['parsedTimes'])
                            // Build a schedule item for each time
                              _buildScheduleItem(
                                time: DateFormat.jm().format(medTime), // Format the time
                                title: data['medicationName'], // Medication name
                                subtitle: '${data['medDosages']} ${data['medUnits']}', // Dosage and units
                                onCheck: () => _logMedicationTaken(data['medicationId']), // Log medication
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
            ),
          ),
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
                icon: Image.asset('assets/images/mmb_schedule_icon.png',
                  height: 38,
                  width: 38,
                ),
                onPressed: () {
                  // Navigate to Schedule page
                  Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const SchedulePage()),
                  );
                },
              ),

              // Medication page icon
              IconButton(
                icon: Image.asset('assets/images/mmb_medication_icon.png',
                  height: 38,
                  width: 38,
                ),
                onPressed: () {
                  // Navigate to medication page
                  Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const MedicationPage()),
                  );
                },
              ),

              // Health data icon
              IconButton(
                icon: Image.asset('assets/images/mmb_health_icon.png',
                  height: 38,
                  width: 38,
                ),
                onPressed: () {
                  // Navigate to health data page
                  Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const HealthDataPage()),
                  );
                },
              ),

              // Progress/milestone icon
              IconButton(
                icon: Image.asset('assets/images/mmb_progress_icon.png',
                  height: 38,
                  width: 38,
                ),
                onPressed: () {
                  // Navigate to milestone page
                  Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const MilestonePage()),
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

          // Log Medication Button
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: onCheck,
          ),
        ],
      ),
    );
  }
}