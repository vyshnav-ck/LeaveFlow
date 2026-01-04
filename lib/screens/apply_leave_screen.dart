// lib/screens/apply_leave_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/leave_model.dart';
import '../providers/leave_provider.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({Key? key}) : super(key: key);

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  int get totalDays {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays.abs() + 1;
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final res = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (res != null) setState(() => _startDate = res);
  }

  Future<void> _pickEnd() async {
    final now = DateTime.now();
    final res = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (res != null) setState(() => _endDate = res);
  }

  Future<void> _submit() async {
    debugPrint("🔥 SUBMIT BUTTON PRESSED");

    if (!_formKey.currentState!.validate()) {
      debugPrint("❌ FORM INVALID");
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick start and end date')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    debugPrint("👤 CURRENT USER = ${user?.uid}");

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

  final leave = LeaveModel(
  id: '',
  uid: user.uid,
  name: _nameCtrl.text.trim(),
  reason: _reasonCtrl.text.trim(),
  startDate: _startDate!.toIso8601String().split('T')[0],
  endDate: _endDate!.toIso8601String().split('T')[0],
  totalDays: totalDays,
  status: 'Pending',
  createdAt: DateTime.now(), // ✅ DateTime ONLY
);


    try {
      await Provider.of<LeaveProvider>(context, listen: false).addLeave(leave);

      debugPrint("✅ LEAVE SUCCESSFULLY SENT TO FIRESTORE");

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave submitted ✅')),
      );
    } catch (e) {
      debugPrint("❌ ADD LEAVE ERROR = $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission failed ❌')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply Leave')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _reasonCtrl,
                decoration: const InputDecoration(labelText: 'Reason'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter reason' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _pickStart,
                      child: Text(_startDate == null
                          ? 'Pick start date'
                          : _startDate!.toIso8601String().split('T')[0]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _pickEnd,
                      child: Text(_endDate == null
                          ? 'Pick end date'
                          : _endDate!.toIso8601String().split('T')[0]),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Text('Total days: $totalDays'),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


