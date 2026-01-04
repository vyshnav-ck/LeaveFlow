import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_basics/providers/leave_provider.dart';
import 'package:flutter_basics/providers/notification_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _deptCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    setState(() => _loading = true);
    try {
      final file = File(picked.path);
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final storageRef = FirebaseStorage.instance.ref().child('user_photos').child('$uid.jpg');

      final snapshot = await storageRef.putFile(file);
      final url = await snapshot.ref.getDownloadURL();

      await Provider.of<UserProvider>(context, listen: false).updateProfile(uid: uid, photoUrl: url);
      await FirebaseAuth.instance.currentUser?.updatePhotoURL(url);
      await FirebaseAuth.instance.currentUser?.reload();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile(UserModel user) async {
    setState(() => _loading = true);
    try {
      await Provider.of<UserProvider>(context, listen: false).updateProfile(
        uid: user.uid,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        department: _deptCtrl.text.trim(),
      );

      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update failed')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final up = Provider.of<UserProvider>(context);
    final user = up.user;

    // ✅ ONLY real loading — NO DEBUG ANYMORE
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_editing) {
      _nameCtrl.text = user.name;
      _phoneCtrl.text = user.phone ?? '';
      _deptCtrl.text = user.department ?? '';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              Provider.of<UserProvider>(context, listen: false).clear();
              Provider.of<LeaveProvider>(context, listen: false).clear();
              Provider.of<NotificationProvider>(context, listen: false).clear();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out')),
              );
            },
          ),
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _editing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 54,
                  backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                  child: user.photoUrl == null ? const Icon(Icons.person, size: 54) : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _loading ? null : _pickAndUploadImage,
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (!_editing) ...[
              Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(user.email),
              const SizedBox(height: 12),
              ListTile(leading: const Icon(Icons.phone), title: Text(user.phone ?? 'Not set')),
              ListTile(leading: const Icon(Icons.apartment), title: Text(user.department ?? 'Not set')),
              ListTile(leading: const Icon(Icons.badge), title: Text('Role: ${user.role}')),
            ] else ...[
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: _deptCtrl, decoration: const InputDecoration(labelText: 'Department')),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: () => _saveProfile(user), child: const Text('Save'))
            ]
          ],
        ),
      ),
    );
  }
}

