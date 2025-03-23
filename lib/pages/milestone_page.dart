import 'package:flutter/material.dart';
import 'package:my_med_buddy_app/Services/authentication.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_med_buddy_app/pages/signup_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'medication_page.dart';
import 'schedule_page.dart';
import 'health_data_page.dart';

class MilestonePage extends StatefulWidget {
  const MilestonePage({super.key});
  @override
  State<MilestonePage> createState() => _MilestonePageState();
}

class _MilestonePageState extends State<MilestonePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _userData;
  bool _isLoading = true; // Track loading state
  bool _hasFirstLog = false; // Track if the user has made their first log

  // Declare obj of auth services class
  final AuthServices _authService = AuthServices();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _checkFirstLog();
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

  // Check if the user has made their first log
  Future<void> _checkFirstLog() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final logsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medicationLogs')
          .get();

      setState(() {
        _hasFirstLog = logsSnapshot.docs.isNotEmpty;
      });
    }
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
            // Streak Icon
            Image.asset(
              'assets/images/mmb_streak_icon.png',
              height: 70,
              width: 60,
            ),
            const SizedBox(width: 8),
            // Streak Counter
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

  // Achievement card widget
  Widget _buildAchievementCard({
    required String title,
    required String description,
    required String iconPath,
    required bool isUnlocked,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.5, // Grey out if not unlocked
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and Title
              Row(
                children: [
                  Image.asset(
                    iconPath,
                    height: 120,
                    width: 120,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? Colors.black : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Description
              Padding(
                padding: const EdgeInsets.only(left: 38),
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 20,
                    color: isUnlocked ? Colors.grey : Colors.grey[400],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE3E3), // Light background color
      appBar: AppBar(
        title: _buildStreakCounter(), // Use the streak counter widget
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Centered title
            Container(
              height: 100, // Adjust height as needed
              alignment: Alignment.center, // Center the text
              child: const Text(
                "Milestones",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),

            // Section Divider
            const Divider(
              thickness: 1,
              color: Colors.grey,
              indent: 20,
              endIndent: 20,
            ),

            // First Log Achievement
            _buildAchievementCard(
              title: "First dose success",
              description: "Logged your first dose—great start to your health journey.",
              iconPath: 'assets/images/mmb_mascot.png',
              isUnlocked: _hasFirstLog, // Unlock if the user has made their first log
            ),

            // Section Divider
            const Divider(
              thickness: 1,
              color: Colors.grey,
              indent: 20,
              endIndent: 20,
            ),

            // Fifty Streak Achievement
            _buildAchievementCard(
              title: "Gain 50 streak points",
              description: "Achieved fifty streak points. Well done!",
              iconPath: 'assets/images/mmb_smiling.png',
              isUnlocked: false, // Locked by default
            ),

            // Section Divider
            const Divider(
              thickness: 1,
              color: Colors.grey,
              indent: 20,
              endIndent: 20,
            ),

            // One Year Adherence Achievement
            _buildAchievementCard(
              title: "Year of Wellness",
              description: "Achieved a full year of adherence and tracking",
              iconPath: 'assets/images/mmb_calendar_icon.png',
              isUnlocked: false, // Locked by default
            ),
          ],
        ),
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
}