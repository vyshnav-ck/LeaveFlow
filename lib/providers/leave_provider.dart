// lib/providers/leave_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/leave_model.dart';

class LeaveProvider extends ChangeNotifier {
  final FirebaseFirestore _fire = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<LeaveModel> leaveList = [];
  StreamSubscription<QuerySnapshot>? _sub;
  bool _isAdminMode = false;

  // ================== LISTEN ==================
  void startListening({bool adminMode = false}) {
    debugPrint('🔥 LeaveProvider.startListening (adminMode=$adminMode)');

    _isAdminMode = adminMode;
    _sub?.cancel();

    final user = _auth.currentUser;
    if (user == null) {
      leaveList = [];
      notifyListeners();
      return;
    }

    Query query = _fire.collection('leaves');

    if (!adminMode) {
      query = query.where('uid', isEqualTo: user.uid);
    }

    _sub = query.snapshots().listen((snapshot) {
      debugPrint('📥 Firestore returned ${snapshot.docs.length} leaves');

      leaveList = snapshot.docs
          .map((d) =>
              LeaveModel.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();

      notifyListeners();
    }, onError: (e) {
      debugPrint('❌ LeaveProvider listen error: $e');
    });
  }

  // ================== ADD ==================
  Future<void> addLeave(LeaveModel leave) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final map = leave.toMap()
      ..['uid'] = user.uid
      ..['createdAt'] = FieldValue.serverTimestamp();

    await _fire.collection('leaves').add(map);
    debugPrint('✅ Leave added');
  }

  // ================== IMPORTANT FIX ==================
  // OLD METHOD — KEEP IT (Admin Dashboard uses this)

  // NEW METHOD — COMMENT SUPPORT
  Future<void> updateLeaveStatusWithComment({
    required String leaveId,
    required String status,
    String? comment,
  }) async {
    debugPrint('🚨 UPDATE LEAVE STATUS WITH COMMENT');
    debugPrint('➡️ status = $status');
    debugPrint('➡️ adminComment = $comment');

    final Map<String, dynamic> updateData = {
      'status': status,
      'reviewedAt': FieldValue.serverTimestamp(),
    };

    if (comment != null && comment.trim().isNotEmpty) {
      updateData['adminComment'] = comment.trim();
    }

    debugPrint('🔥 FIRESTORE UPDATE DATA = $updateData');

    await _fire.collection('leaves').doc(leaveId).update(updateData);
  }

  // ================== DELETE ==================
  Future<void> deleteLeave(String docId) async {
    await _fire.collection('leaves').doc(docId).delete();
  }

  // ================== CLEAR ==================
  void clear() {
    debugPrint('🧹 LeaveProvider cleared');
    leaveList = [];
    _sub?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}




