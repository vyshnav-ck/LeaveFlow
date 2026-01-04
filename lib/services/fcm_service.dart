import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  static final _messaging = FirebaseMessaging.instance;
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> init() async {
    try {
      // ✅ Request permission (important for iOS)
      await _messaging.requestPermission();

      final token = await _messaging.getToken();
      debugPrint("🔥 FCM TOKEN = $token");

      final user = _auth.currentUser;
      if (user == null || token == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
      });

      debugPrint("✅ FCM Token saved to user doc");

    } catch (e) {
      debugPrint("❌ FCM Init Error: $e");
    }
  }
}
