// lib/main_nav.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'screens/leave_list_screen.dart';
import 'screens/apply_leave_screen.dart';
import 'screens/leave_list_screen.dart';
import 'screens/leave_detail_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/profile_screen.dart';
import 'screens/home_screen.dart'; // replace if you have different home screen
import 'providers/leave_provider.dart';
import 'package:provider/provider.dart';
import 'providers/notification_provider.dart';


class MainNav extends StatefulWidget {
  const MainNav({Key? key}) : super(key: key);

  @override
  _MainNavState createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _currentIndex = 0;
  late bool isAdmin;

  // Admin email (you provided)
  static const String _adminEmail = 'vyshnavck80@gmail.com';

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    isAdmin = (user?.email?.toLowerCase() == _adminEmail.toLowerCase());

    // Ensure leave provider starts with appropriate mode (in case MainNav is reached again)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LeaveProvider>(context, listen: false).startListening(adminMode: isAdmin);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Build pages list dynamically depending on isAdmin
    final List<Widget> pages = [
      // Replace HomeScreen with your actual home screen widget if named differently
      const HomeScreen(),
      const LeaveListScreen(),
      ProfileScreen(),
    ];

    final List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Leaves'),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];

    if (isAdmin) {
      pages.add(const AdminDashboard());
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'));
    }

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
  selectedItemColor: const Color.fromARGB(255, 2, 2, 2),
  unselectedItemColor: const Color.fromARGB(255, 116, 106, 106),
        currentIndex: _currentIndex,
        items: items,
        onTap: (i) {
          setState(() => _currentIndex = i);
        },
      ),
      // optional floating action for apply leave on Leaves tab only
      floatingActionButton: _currentIndex == 1 // Leaves tab index
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ApplyLeaveScreen()));
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

