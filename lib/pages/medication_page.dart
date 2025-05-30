import 'package:flutter/material.dart';
import 'package:my_med_buddy_app/Services/authentication.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_med_buddy_app/pages/signup_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'schedule_page.dart';
import 'health_data_page.dart';
import 'milestone_page.dart';
import 'add_med_page.dart';
import 'package:my_med_buddy_app/widgets/section_divider.dart';
import 'appointment_page.dart';

class MedicationPage extends StatefulWidget {
  const MedicationPage({super.key});
  @override
  State<MedicationPage> createState() => _MedicationPageState();
}

class _MedicationPageState extends State<MedicationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _userData;
  bool _isLoading = true; // Track loading state

  //declare obj of auth services class
  final AuthServices _authService = AuthServices();

  //declare text editing controller for search bar
  final _searchBarController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _searchBarController.dispose();
    super.dispose();
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

  //Method to edit user created medication schedules
  void _navigateToEditMedicationPage(
      BuildContext context, QueryDocumentSnapshot med) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedPage(
          medicationData: med.data() as Map<String,
              dynamic>, // Pass the medication data to the edit page
          medicationId: med.id, // Pass the document ID for updating
        ),
      ),
    );
  }

  //Method to delete user created medication schedules
  void _deleteMedication(String medicationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('medications')
          .doc(medicationId)
          .delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Medication deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete medication: $e')),
      );
    }
  }

  //method to use sign out from authentication.dart
  void _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    //navigates back to signup_login screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => SignupLoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFFEF),
      // Light background color
      appBar: AppBar(
        title: Row(
          children: [
            // Streak Counter with Flame Icon

            const Text(
              "Current Medications", // Replace with dynamic streak count
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        // Disable default leading icon (hamburger menu)
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
              title: const Text('Appointments'),
              onTap: () {
                // Navigate to Calendar Page
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AppointmentPage(),
                  ),
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

      //Body
      body: Column(
        children: [
          //SectionDivider(),
          //sign up button
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddMedPage(),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFFFFE3E3),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: Color(0xFFFF5050),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Add Medication',
                        style: TextStyle(
                          color: Color(0xFF545354),
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      SizedBox(width: 20),
                      const Icon(Icons.add, color: Color(0xFF545354), size: 35)
                    ],
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 10),
          SectionDivider(),
          SizedBox(height: 10),

          //display all user medications
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_auth.currentUser!.uid)
                  .collection('medications')
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No medications found'));
                }

                final medications = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: medications.length,
                  itemBuilder: (context, index) {
                    final med = medications[index];
                    final data = med.data() as Map<String, dynamic>;

                    // Handle missing fields gracefully
                    final medFrequency =
                        data['medFrequency'] ?? 1; // Default to 1 if missing
                    final medTimes = data['medTimes'];

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        tileColor: Color(0xFFFFE3E3),
                        leading: SizedBox(
                          height: 85,
                          width: 55,
                          child: Image.asset(
                            'assets/images/mmb_pill_icon.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        title: Text(
                          med['medicationName'],
                          style: TextStyle(
                            color: Color(0xFFFF6565),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        subtitle: Text(
                          'Schedule: $medFrequency times daily',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(
                            Icons
                                .more_vert, // Use a vertical dots icon for the menu
                            color: Colors.black,
                            size: 20,
                          ),
                          onSelected: (value) {
                            if (value == 'edit') {
                              // Navigate to the edit page
                              _navigateToEditMedicationPage(context, med);
                            } else if (value == 'delete') {
                              // Delete the medication
                              _deleteMedication(med.id);
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem<String>(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ),
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
                icon: Image.asset(
                  'assets/images/mmb_schedule_icon.png',
                  height: 38,
                  width: 38,
                ),
                onPressed: () {
                  //Navigate to Schedule page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SchedulePage()),
                  );
                },
              ),

              //medication page icon
              IconButton(
                icon: Image.asset(
                  'assets/images/mmb_medication_icon.png',
                  height: 38,
                  width: 38,
                ),
                onPressed: () {
                  //Navigate to medication page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MedicationPage()),
                  );
                },
              ),

              //health data icon
              IconButton(
                icon: Image.asset(
                  'assets/images/mmb_health_icon.png',
                  height: 38,
                  width: 38,
                ),
                onPressed: () {
                  //Navigate to health data page
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
                  //Navigate to milestone page
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
}
