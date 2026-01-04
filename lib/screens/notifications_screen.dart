import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'leave_detail_screen.dart';        // adjust path if needed
import 'employee_detail_screen.dart';
import 'package:flutter_basics/models/leave_model.dart';
import 'package:flutter_basics/models/user_model.dart';


class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final np = Provider.of<NotificationProvider>(context);
    final list = np.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => np.markAllRead(),
            child: const Text('Mark all', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: list.isEmpty
          ? const Center(child: Text('No notifications'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final AppNotification n = list[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: n.read ? null : Colors.blue.shade50,
                  child: ListTile(
                    title: Text(n.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(n.body),
                        const SizedBox(height: 6),
                        Text(n.createdAt.toLocal().toString().split('.').first, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    onTap: () async {
  // mark read (fire-and-forget)
  try {
    await Provider.of<NotificationProvider>(context, listen: false).markRead(n.id);
  } catch (e) {
    debugPrint('markRead failed: $e');
  }

  final meta = n.meta ?? {};
  final leaveId = meta['leaveId'] ?? meta['leave_id'];

  if (leaveId != null && leaveId.toString().isNotEmpty) {
    // show loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final doc = await FirebaseFirestore.instance.collection('leaves').doc(leaveId.toString()).get();

      // safely remove loader if possible
      if (Navigator.canPop(context)) Navigator.of(context).pop();

      if (doc.exists) {
        final map = doc.data()! as Map<String, dynamic>;
        final leave = LeaveModel.fromMap(doc.id, map);
        Navigator.push(context, MaterialPageRoute(builder: (_) => LeaveDetailScreen(leave: leave,)));
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave not found')));
        return;
      }
    } catch (e) {
      // ensure dialog removed
      if (Navigator.canPop(context)) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening leave: $e')));
      return;
    }
  }

  // fallback: open user profile if uid present
  final uid = meta['uid'] ?? meta['userId'];
  if (uid != null && uid.toString().isNotEmpty) {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid.toString()).get();
      if (doc.exists) {
        final userMap = doc.data()! as Map<String, dynamic>;
        final userModel = UserModel.fromMap(userMap);
        Navigator.push(context, MaterialPageRoute(builder: (_) => EmployeeDetailScreen(user: userModel)));
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not found')));
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening user: $e')));
      return;
    }
  }

  // final fallback: show body dialog
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(n.title),
      content: Text(n.body),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    ),
  );
},

                  ),
                );
              },
            ),
    );
  }
}
