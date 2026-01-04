// lib/screens/employee_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final UserModel user;
  const EmployeeDetailScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  bool _loadingRoleChange = false;
  bool _deleting = false;

  final _fire = FirebaseFirestore.instance;

  Future<void> _changeRole(String uid, String newRole) async {
    setState(() => _loadingRoleChange = true);
    try {
      await _fire.collection('users').doc(uid).update({'role': newRole});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Role changed to $newRole')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to change role: $e')));
    } finally {
      if (mounted) setState(() => _loadingRoleChange = false);
    }
  }

  Future<void> _deleteUserDoc(String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete user doc?'),
        content: const Text('This will delete the user document in Firestore but NOT the Firebase Auth account. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await _fire.collection('users').doc(uid).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User document deleted')));
        Navigator.pop(context); // go back to list
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  // helper to build a stream that counts leaves by status
  Stream<int> _countLeavesStream(String uid, {String? status}) {
    Query q = _fire.collection('leaves').where('uid', isEqualTo: uid);
    if (status != null) q = q.where('status', isEqualTo: status);
    return q.snapshots().map((s) => s.docs.length);
  }

  String _formatDate(DateTime d) => DateFormat.yMMMd().format(d);

  @override
  Widget build(BuildContext context) {
    final u = widget.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(u.name.isNotEmpty ? u.name : 'Employee'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'promote') {
                await _changeRole(u.uid, 'admin');
              } else if (v == 'demote') {
                await _changeRole(u.uid, 'user');
              } else if (v == 'delete') {
                await _deleteUserDoc(u.uid);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'promote', child: Text('Promote → admin')),
              const PopupMenuItem(value: 'demote', child: Text('Demote → user')),
              const PopupMenuItem(value: 'delete', child: Text('Delete doc')),
            ],
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // profile top
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: u.photoUrl != null ? NetworkImage(u.photoUrl!) : null,
                  child: u.photoUrl == null ? Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 24)) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.name.isNotEmpty ? u.name : '(No name)', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(u.email, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 6),
                      Text('Role: ${u.role}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // details card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: Text(u.phone ?? 'Not set'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.apartment),
                      title: Text(u.department ?? 'Not set'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text('Joined: ${_formatDate(u.joinedAt)}'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // leave stats section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: StreamBuilder<int>(
                    stream: _countLeavesStream(u.uid),
                    builder: (c, s) {
                      final total = s.hasData ? s.data! : 0;
                      return _statCard('Total leaves', total.toString());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StreamBuilder<int>(
                    stream: _countLeavesStream(u.uid, status: 'Pending'),
                    builder: (c, s) => _statCard('Pending', s.hasData ? s.data!.toString() : '0'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StreamBuilder<int>(
                    stream: _countLeavesStream(u.uid, status: 'Approved'),
                    builder: (c, s) => _statCard('Approved', s.hasData ? s.data!.toString() : '0'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: StreamBuilder<int>(
                    stream: _countLeavesStream(u.uid, status: 'Rejected'),
                    builder: (c, s) => _statCard('Rejected', s.hasData ? s.data!.toString() : '0'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Container()), // placeholder for balance layout
              ],
            ),

            const SizedBox(height: 18),

            // action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loadingRoleChange ? null : () {
                      final newRole = (u.role == 'admin') ? 'user' : 'admin';
                      _changeRole(u.uid, newRole);
                    },
                    icon: const Icon(Icons.swap_horiz),
                    label: _loadingRoleChange ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(u.role == 'admin' ? 'Demote to user' : 'Promote to admin'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _deleting ? null : () => _deleteUserDoc(u.uid),
                    icon: const Icon(Icons.delete),
                    label: _deleting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Delete doc'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // optional: raw doc viewer for debug
            ExpansionTile(
              title: const Text('Raw user document (debug)'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(u.uid).snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) return const Text('Loading...');
                      if (!snap.hasData || !snap.data!.exists) return const Text('No doc');
                      final map = snap.data!.data() as Map<String, dynamic>;
                      return Text(map.toString());
                    },
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
}
