import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _fire = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _sub;

  List<AppNotification> notifications = [];
  int unreadCount = 0;

  void startListening() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('❌ NotificationProvider: No user');
      return;
    }

    _sub?.cancel();

    debugPrint('🔔 NotificationProvider listening for ${user.uid}');

    _sub = _fire
        .collection('notifications')
        .where('uid', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      notifications = snap.docs.map((d) {
        return AppNotification.fromMap(
          d.id,
          d.data() as Map<String, dynamic>,
        );
      }).toList();

      unreadCount = notifications.where((n) => !n.read).length;

      debugPrint('📩 Notifications loaded: ${notifications.length}');
      notifyListeners();
    }, onError: (e) {
      debugPrint('❌ Notification listen error: $e');
    });
  }

  Future<void> markRead(String id) async {
    await _fire.collection('notifications').doc(id).update({'read': true});
  }

  Future<void> markAllRead() async {
    final batch = _fire.batch();
    for (final n in notifications.where((n) => !n.read)) {
      batch.update(_fire.collection('notifications').doc(n.id), {
        'read': true,
      });
    }
    await batch.commit();
  }

  void clear() {
    notifications = [];
    unreadCount = 0;
    _sub?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}


