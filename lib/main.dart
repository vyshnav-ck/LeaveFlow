import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'providers/user_provider.dart';
import 'providers/counter_provider.dart';
import 'providers/leave_provider.dart';
import 'providers/notification_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/fcm_service.dart';
import 'main_nav.dart';
import 'auth/login_screen.dart';

Future<void> _ensureUserDocExists() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'phone': null,
        'department': null,
        'role': 'user',
        'photoUrl': user.photoURL,
        'joinedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Created missing user doc for ${user.uid}');
    } else {
      debugPrint('✅ User doc exists for ${user.uid}');
    }
  } catch (e) {
    debugPrint('❌ ensureUserDocExists error: $e');
  }
}

Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("🔔 Background message received: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CounterProvider()),
        ChangeNotifierProvider(create: (_) => LeaveProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Basics',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const AuthGate(),
      ),
    );
  }
}

/// ✅ AUTH GATE – THE MOST IMPORTANT FILE IN YOUR APP
class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _lastUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ✅ LOADING STATE
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ✅ LOGGED OUT
        if (!snapshot.hasData) {
          _lastUid = null;
          return LoginScreen();
        }

        // ✅ LOGGED IN
        final user = snapshot.data!;
        final currentUid = user.uid;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
  final fcm = FirebaseMessaging.instance;

  // ✅ Request permission (Android 13+)
  await fcm.requestPermission();

  // ✅ Get FCM token
  final token = await fcm.getToken();
  debugPrint("📱 FCM TOKEN = $token");

  // ✅ Save token to Firestore
  final uid = FirebaseAuth.instance.currentUser!.uid;

  await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .set({'fcmToken': token}, SetOptions(merge: true));

  // ✅ Foreground message listener
  FirebaseMessaging.onMessage.listen((message) {
    debugPrint("🔔 Foreground message: ${message.notification?.title}");
  });
});

        // ✅ ONLY WHEN USER CHANGES (ADMIN <-> USER SWITCH)
        if (_lastUid != currentUid) {
          debugPrint('🔥 AUTHGATE USER SWITCH DETECTED: $_lastUid → $currentUid');

          _lastUid = currentUid;

          final isAdmin =
              user.email?.toLowerCase() == 'vyshnavck80@gmail.com';

          WidgetsBinding.instance.addPostFrameCallback((_) async {
            debugPrint('🔁 AUTH SWITCH → UID = $currentUid | Admin = $isAdmin');

            // ✅ ENSURE USER DOC EXISTS
            await _ensureUserDocExists();

            // ✅ START PROVIDERS CLEANLY
            Provider.of<UserProvider>(context, listen: false).startListening();

            Provider.of<LeaveProvider>(context, listen: false)
                .startListening(adminMode: isAdmin);

            Provider.of<NotificationProvider>(context, listen: false)
                .startListening();
                
                FCMService.init();
          });
        }

        return MainNav(); // ✅ ENTER APP
      },
    );
  }
}


