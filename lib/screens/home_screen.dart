// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/leave_provider.dart';
import '../providers/user_provider.dart';
import '../screens/apply_leave_screen.dart';
import '../screens/leave_list_screen.dart';
import '../screens/admin_dashboard.dart';
import '../screens/admin_analytics_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final leaveProvider = Provider.of<LeaveProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    final isAdmin = userProvider.user?.role == 'admin';

    final totalLeaves = leaveProvider.leaveList.length;
    final pending = leaveProvider.leaveList.where((l) => l.status == 'Pending').length;
    final approved = leaveProvider.leaveList.where((l) => l.status == 'Approved').length;
    final rejected = leaveProvider.leaveList.where((l) => l.status == 'Rejected').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LeaveFlow'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 👋 GREETING
            Text(
              'Hello, ${userProvider.user?.name ?? user?.email ?? 'User'} 👋',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              isAdmin ? 'Role: Admin' : 'Role: Employee',
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 24),

            /// 🔘 ACTION BUTTONS
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (!isAdmin)
                  _actionButton(
                    context,
                    label: 'Apply Leave',
                    icon: Icons.add,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ApplyLeaveScreen()),
                    ),
                  ),

                _actionButton(
                  context,
                  label: 'My Leaves',
                  icon: Icons.list_alt,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LeaveListScreen()),
                  ),
                ),

                if (isAdmin)
                  _actionButton(
                    context,
                    label: 'Admin Dashboard',
                    icon: Icons.admin_panel_settings,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminDashboard()),
                    ),
                  ),

                if (isAdmin)
                  _actionButton(
                    context,
                    label: 'Analytics',
                    icon: Icons.insights,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen()),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 32),

            /// 📊 QUICK STATS
            const Text(
              'Quick Stats',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statCard('Total', totalLeaves, Colors.blue),
                _statCard('Pending', pending, Colors.orange),
                _statCard('Approved', approved, Colors.green),
                _statCard('Rejected', rejected, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================== UI HELPERS ==================

  Widget _actionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 2 - 24,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _statCard(String title, int value, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}
