import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _fire = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? user;
  StreamSubscription<DocumentSnapshot>? _sub;

  /// ✅ START LISTENING TO USER DOC
  void startListening() {
    final authUser = _auth.currentUser;
    if (authUser == null) return;

    _sub?.cancel();
    _sub = _fire
        .collection('users')
        .doc(authUser.uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null) {
        user = UserModel.fromMap(doc.data()!);
        notifyListeners();
      }
    });
  }

  /// ✅ UPDATE PROFILE
  Future<void> updateProfile({
    required String uid,
    String? name,
    String? phone,
    String? department,
    String? photoUrl,
  }) async {
    final map = <String, dynamic>{};

    if (name != null) map['name'] = name;
    if (phone != null) map['phone'] = phone;
    if (department != null) map['department'] = department;
    if (photoUrl != null) map['photoUrl'] = photoUrl;

    await _fire.collection('users').doc(uid).set(map, SetOptions(merge: true));
  }

  /// ✅ CLEAR ON LOGOUT
  void clear() {
    user = null;
    _sub?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
