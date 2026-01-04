// lib/screens/admin_users_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import 'employee_detail_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  _AdminUsersScreenState createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _search = '';
  String _filterRole = 'All';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _usersStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .orderBy('joinedAt', descending: true)
        .snapshots();
  }

  List<UserModel> _applyFilters(List<UserModel> list) {
    var filtered = list;
    if (_filterRole != 'All') {
      filtered = filtered.where((u) => (u.role ?? 'user') == _filterRole).toList();
    }
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      filtered = filtered
          .where((u) =>
              u.name.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              (u.department ?? '').toLowerCase().contains(q))
          .toList();
    }
    return filtered;
  }

  Future<void> _changeRole(String uid, String newRole) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({'role': newRole});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Role updated to $newRole')));
  }

  Future<void> _deleteUserDoc(String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete user doc?'),
        content: const Text('This will delete the user document in Firestore but NOT the Firebase Auth account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User document deleted')));
  }

  Widget _buildTile(UserModel u, {required bool isMine}) {
    // where you return the ListTile for each user
return Card(
  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
  child: ListTile(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmployeeDetailScreen(user: u),
        ),
      );
    },
    leading: CircleAvatar(
      backgroundImage: u.photoUrl != null ? NetworkImage(u.photoUrl!) : null,
      child: u.photoUrl == null
          ? Text(
              u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            )
          : null,
    ),
    title: Text(u.name),
    subtitle: Text('${u.email}\n${u.department ?? 'No dept'}'),
    isThreeLine: true,
    trailing: Wrap(
      spacing: 6,
      children: [
        Chip(label: Text(u.role)),
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
          itemBuilder: (ctx) => const [
            PopupMenuItem(value: 'promote', child: Text('Promote → admin')),
            PopupMenuItem(value: 'demote', child: Text('Demote → user')),
            PopupMenuItem(value: 'delete', child: Text('Delete doc')),
          ],
        ),
      ],
    ),
  ),
);


  }

  @override
  Widget build(BuildContext context) {
    final current = Provider.of<UserProvider>(context).user;
    final currentUid = current?.uid;
    final currentRole = current?.role?.toLowerCase();

    // admin guard: check role or fallback to your admin email
    final isAdmin = (currentRole == 'admin') || (current?.email?.toLowerCase() == 'vyshnavck80@gmail.com');

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Employees')),
        body: const Center(child: Text('You are not authorized to view this page')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Management'),
        actions: [
          SizedBox(
            width: 200,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(isDense: true, hintText: 'Search name/email/department', prefixIcon: Icon(Icons.search)),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => _filterRole = v),
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'All', child: Text('All')),
              PopupMenuItem(value: 'admin', child: Text('Admin')),
              PopupMenuItem(value: 'user', child: Text('User')),
            ],
            icon: const Icon(Icons.filter_list),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _usersStream(),
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('Error loading users'));
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs;
          final users = docs.map((d) {
            final map = d.data() as Map<String, dynamic>;
            return UserModel.fromMap(map);
          }).toList();

          final filtered = _applyFilters(users);

          if (filtered.isEmpty) return const Center(child: Text('No users matching filters'));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final u = filtered[i];
              return _buildTile(u, isMine: u.uid == currentUid);
            },
          );
        },
      ),
    );
  }
}
