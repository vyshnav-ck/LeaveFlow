// lib/screens/leave_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/leave_model.dart';
import '../providers/leave_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/status_chip.dart';

class LeaveDetailScreen extends StatefulWidget {
  final LeaveModel leave;

  const LeaveDetailScreen({
    Key? key,
    required this.leave,
  }) : super(key: key);

  @override
  State<LeaveDetailScreen> createState() => _LeaveDetailScreenState();
}

class _LeaveDetailScreenState extends State<LeaveDetailScreen> {
  late LeaveModel leave;

  @override
  void initState() {
    super.initState();
    leave = widget.leave;
  }

  // ================= APPROVE (NO COMMENT) =================
  Future<void> _approve() async {
    try {
      await Provider.of<LeaveProvider>(context, listen: false)
          .updateLeaveStatusWithComment(
        leaveId: leave.id,
        status: 'Approved',
        comment: null,
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave approved ✅')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Approval failed ❌')),
      );
    }
  }

  // ================= REJECT WITH COMMENT =================
Future<void> _rejectWithComment() async {
  final commentCtrl = TextEditingController();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Reject Leave'),
      content: TextField(
        controller: commentCtrl,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Reason for rejection',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
  onPressed: _rejectWithComment,
  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
  child: const Text('Reject'),
),
      ],
    ),
  );

  if (confirmed != true) return;

  await Provider.of<LeaveProvider>(context, listen: false)
      .updateLeaveStatusWithComment(
    leaveId: leave.id, // ✅ VALID HERE
    status: 'Rejected',
    comment: commentCtrl.text.trim(), // ✅ STRING PASSED
  );

  Navigator.pop(context);
}

  // ================= DELETE =================
  Future<void> _deleteLeave() async {
    try {
      await Provider.of<LeaveProvider>(context, listen: false)
          .deleteLeave(leave.id);

      Navigator.pop(context, {'action': 'deleted'});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delete failed ❌')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userProvider = Provider.of<UserProvider>(context);

    final bool isAdmin = userProvider.user?.role == 'admin';
    final bool isOwner = currentUser != null && currentUser.uid == leave.uid;
    final bool isPending = leave.status == 'Pending';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Details'),
        actions: [
          if (isAdmin || isOwner)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteLeave,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Name', leave.name),
            _row('Reason', leave.reason),
            _row('From', leave.startDate),
            _row('To', leave.endDate),
            _row('Total days', leave.totalDays.toString()),
            const SizedBox(height: 12),
            StatusChip(status: leave.status),

            if (leave.adminComment != null &&
                leave.adminComment!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _row('Admin comment', leave.adminComment!),
            ],

            const SizedBox(height: 24),

            // ================= ADMIN CONTROLS =================
            if (isAdmin && isPending)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _approve,
                      child: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _rejectWithComment,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),

            // ================= USER DELETE =================
            if (!isAdmin && isOwner)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _deleteLeave,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text('Delete'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}





